import AppKit
import NoSleepCore

private enum L10n {
    static var keepDisplayAwake: String {
        string("menu.keep_display_awake", defaultValue: "Keep Display Awake")
    }

    static var quit: String {
        string("menu.quit", defaultValue: "Quit NoSleep")
    }

    static var activeStatus: String {
        string("status.active", defaultValue: "Display and idle sleep are blocked")
    }

    static var inactiveStatus: String {
        string("status.inactive", defaultValue: "NoSleep is off")
    }

    static var enabledAccessibilityLabel: String {
        string("accessibility.enabled", defaultValue: "NoSleep is on")
    }

    static var disabledAccessibilityLabel: String {
        string("accessibility.disabled", defaultValue: "NoSleep is off")
    }

    static var enabledTooltip: String {
        string(
            "tooltip.enabled",
            defaultValue: "NoSleep is on — the display and Mac will not sleep automatically"
        )
    }

    static var disabledTooltip: String {
        string("tooltip.disabled", defaultValue: "NoSleep is off")
    }

    static var enableFailedTitle: String {
        string("alert.enable_failed.title", defaultValue: "Could Not Enable NoSleep")
    }

    static var ok: String {
        string("button.ok", defaultValue: "OK")
    }

    static var displaySleepTarget: String {
        string("error.assertion.display_target", defaultValue: "display sleep")
    }

    static var systemSleepTarget: String {
        string("error.assertion.system_target", defaultValue: "system sleep")
    }

    static var assertionErrorFormat: String {
        string(
            "error.assertion.format",
            defaultValue: "macOS did not allow NoSleep to prevent %@ (IOKit error code: %d)."
        )
    }

    private static func string(_ key: String, defaultValue: String) -> String {
        NSLocalizedString(
            key,
            tableName: nil,
            bundle: .main,
            value: defaultValue,
            comment: ""
        )
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum DefaultsKey {
        static let preventionEnabled = "preventionEnabled"
    }

    private let powerAssertions = PowerAssertionController()
    private let defaults = UserDefaults.standard
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let statusMenu = NSMenu()

    private lazy var statusDescriptionItem = NSMenuItem(
        title: "",
        action: nil,
        keyEquivalent: ""
    )

    private lazy var preventionItem = NSMenuItem(
        title: L10n.keepDisplayAwake,
        action: #selector(togglePrevention),
        keyEquivalent: ""
    )

    override init() {
        super.init()
        defaults.register(defaults: [
            DefaultsKey.preventionEnabled: false
        ])
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenu()
        configureStatusItem()

        if defaults.bool(forKey: DefaultsKey.preventionEnabled) {
            enablePrevention(showError: true)
        }

        updateInterface()
    }

    func applicationWillTerminate(_ notification: Notification) {
        powerAssertions.disable()
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateInterface()
    }

    private func configureMenu() {
        statusMenu.delegate = self
        statusMenu.autoenablesItems = false

        statusDescriptionItem.isEnabled = false

        preventionItem.target = self
        preventionItem.isEnabled = true

        let quitItem = NSMenuItem(
            title: L10n.quit,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp

        statusMenu.items = [
            statusDescriptionItem,
            .separator(),
            preventionItem,
            .separator(),
            quitItem
        ]
    }

    private func configureStatusItem() {
        statusItem.menu = statusMenu

        guard let button = statusItem.button else {
            return
        }

        button.imagePosition = .imageOnly
    }

    @objc
    private func togglePrevention() {
        if powerAssertions.isEnabled {
            powerAssertions.disable()
            defaults.set(false, forKey: DefaultsKey.preventionEnabled)
        } else {
            enablePrevention(showError: true)
        }

        updateInterface()
    }

    private func enablePrevention(showError: Bool) {
        do {
            try powerAssertions.enable()
            defaults.set(true, forKey: DefaultsKey.preventionEnabled)
        } catch {
            powerAssertions.disable()
            defaults.set(false, forKey: DefaultsKey.preventionEnabled)

            if showError {
                present(error: error)
            }
        }
    }

    private func updateInterface() {
        let enabled = powerAssertions.isEnabled

        preventionItem.state = enabled ? .on : .off
        statusDescriptionItem.title = enabled ? L10n.activeStatus : L10n.inactiveStatus

        guard let button = statusItem.button else {
            return
        }

        let symbolName = enabled ? "sun.max.fill" : "moon.zzz"
        let accessibilityDescription = enabled
            ? L10n.enabledAccessibilityLabel
            : L10n.disabledAccessibilityLabel
        let baseImage = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: accessibilityDescription
        )
        let image = baseImage?.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        )
        image?.isTemplate = true

        button.image = image
        button.toolTip = enabled
            ? L10n.enabledTooltip
            : L10n.disabledTooltip
        button.setAccessibilityLabel(accessibilityDescription)
    }

    private func present(error: Error) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.enableFailedTitle
        alert.informativeText = localizedDescription(for: error)
        alert.addButton(withTitle: L10n.ok)
        alert.runModal()
    }

    private func localizedDescription(for error: Error) -> String {
        guard let assertionError = error as? PowerAssertionController.AssertionError else {
            return error.localizedDescription
        }

        let target = switch assertionError.kind {
        case .display: L10n.displaySleepTarget
        case .system: L10n.systemSleepTarget
        }

        return String(
            format: L10n.assertionErrorFormat,
            target,
            assertionError.code
        )
    }
}
