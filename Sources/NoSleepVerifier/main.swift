import Foundation
import NoSleepCore

enum VerificationError: LocalizedError {
    case unexpectedState(String)

    var errorDescription: String? {
        switch self {
        case let .unexpectedState(message):
            message
        }
    }
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw VerificationError.unexpectedState(message)
    }
}

do {
    let controller = PowerAssertionController(reason: "NoSleep verification")
    defer { controller.disable() }

    try require(!controller.isEnabled, "A new controller is already enabled.")

    try controller.enable()
    try require(controller.isEnabled, "The assertions were not activated.")

    // A second enable must not leak a duplicate pair of assertions.
    try controller.enable()
    try require(controller.isEnabled, "Calling enable twice changed the active state.")

    if CommandLine.arguments.contains("--hold") {
        print("Assertions are active and will remain active for 10 seconds.")
        fflush(stdout)
        Thread.sleep(forTimeInterval: 10)
    }

    controller.disable()
    try require(!controller.isEnabled, "The assertions were not released.")

    // Releasing an already-disabled controller must remain harmless.
    controller.disable()
    try require(!controller.isEnabled, "Calling disable twice changed the state.")

    print("NoSleepVerifier: all checks passed.")
} catch {
    fputs("NoSleepVerifier: \(error.localizedDescription)\n", stderr)
    exit(EXIT_FAILURE)
}
