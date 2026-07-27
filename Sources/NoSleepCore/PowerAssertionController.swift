import Foundation
import IOKit.pwr_mgt

/// Manages the two macOS power assertions used by NoSleep.
///
/// Assertions are process-scoped. macOS automatically removes them if the app
/// exits unexpectedly; `disable()` releases them immediately during normal use.
public final class PowerAssertionController {
    public enum AssertionKind: String, Equatable, Sendable {
        case display
        case system
    }

    public struct AssertionError: LocalizedError, Equatable, Sendable {
        public let kind: AssertionKind
        public let code: IOReturn

        public var errorDescription: String? {
            let target = switch kind {
            case .display: "display sleep"
            case .system: "system sleep"
            }

            return "macOS did not allow NoSleep to prevent \(target) (IOKit error code: \(code))."
        }
    }

    private let reason: CFString
    private var displayAssertionID: IOPMAssertionID?
    private var systemAssertionID: IOPMAssertionID?

    public var isEnabled: Bool {
        displayAssertionID != nil && systemAssertionID != nil
    }

    public init(reason: String = "NoSleep keeps the display and Mac awake") {
        self.reason = reason as CFString
    }

    /// Prevents display idle sleep and system idle sleep.
    ///
    /// Calling this method more than once is safe and does not create duplicate
    /// assertions.
    public func enable() throws {
        guard !isEnabled else {
            return
        }

        // Clear any partial state before attempting to create both assertions.
        disable()

        var newDisplayAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
        let displayResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &newDisplayAssertionID
        )

        guard displayResult == kIOReturnSuccess else {
            throw AssertionError(kind: .display, code: displayResult)
        }

        var newSystemAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
        let systemResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &newSystemAssertionID
        )

        guard systemResult == kIOReturnSuccess else {
            IOPMAssertionRelease(newDisplayAssertionID)
            throw AssertionError(kind: .system, code: systemResult)
        }

        displayAssertionID = newDisplayAssertionID
        systemAssertionID = newSystemAssertionID
    }

    /// Releases all active assertions. Calling this method repeatedly is safe.
    public func disable() {
        if let displayAssertionID {
            IOPMAssertionRelease(displayAssertionID)
            self.displayAssertionID = nil
        }

        if let systemAssertionID {
            IOPMAssertionRelease(systemAssertionID)
            self.systemAssertionID = nil
        }
    }

    deinit {
        disable()
    }
}
