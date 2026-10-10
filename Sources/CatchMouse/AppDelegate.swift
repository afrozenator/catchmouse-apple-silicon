import AppKit

/// Wires together the display manager, global hotkeys, the menu-bar UI and the
/// Preferences window, and keeps the hotkeys in sync as displays change or the
/// user edits their shortcuts.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let displays = DisplayManager()
    private let hotKeys = HotKeyCenter()
    private let store = HotKeyStore.shared
    private let openPreferencesOnLaunch: Bool
    private var menu: StatusMenuController!
    private lazy var preferences = PreferencesWindowController(displays: displays, store: store) { [weak self] in
        self?.reload()
    }

    init(openPreferencesOnLaunch: Bool = false) {
        self.openPreferencesOnLaunch = openPreferencesOnLaunch
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        menu = StatusMenuController(displays: displays, store: store) { [weak self] action in
            self?.perform(action)
        }
        reload()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        if openPreferencesOnLaunch { preferences.show() }
    }

    @objc private func screensChanged() { reload() }

    /// Re-register hotkeys and rebuild the menu to match the current displays
    /// and the user's stored shortcuts.
    private func reload() {
        menu.shortcutWarnings = registerHotKeys()
        menu.rebuild()
    }

    private func perform(_ action: MenuAction) {
        switch action {
        case .moveTo(let index):
            let ids = displays.orderedDisplays()
            if ids.indices.contains(index) { displays.moveCursor(to: ids[index]) }
        case .next:
            displays.moveToAdjacentDisplay(forward: true)
        case .previous:
            displays.moveToAdjacentDisplay(forward: false)
        case .openPreferences:
            preferences.show()
        case .identifyDisplays:
            DisplayIdentifier.flash(displays: displays)
        }
    }

    private func registerHotKeys() -> [String] {
        hotKeys.unregisterAll()
        var warnings: [String] = []
        var used = Set<KeyCombo>()

        func register(_ combo: KeyCombo, action: String, handler: @escaping () -> Void) {
            guard used.insert(combo).inserted else {
                warnings.append("\(action): \(combo.displayString) already assigned")
                return
            }
            if !hotKeys.register(keyCode: combo.keyCode, modifiers: combo.carbonModifiers, handler: handler) {
                warnings.append("\(action): \(combo.displayString) unavailable")
            }
        }

        // Per-display jump keys (user binding, or positional default).
        for (index, id) in displays.orderedDisplays().enumerated() {
            let key = displays.stableKey(for: id)
            guard let combo = Shortcuts.jumpCombo(index: index, displayKey: key, store: store) else { continue }
            register(combo, action: "Display \(index + 1)") { [weak self] in
                guard let self, let target = self.displays.display(forStableKey: key) else { return }
                self.displays.moveCursor(to: target)
            }
        }

        // Cycle keys.
        if let next = Shortcuts.nextCombo(store) {
            register(next, action: "Next display") { [weak self] in
                self?.displays.moveToAdjacentDisplay(forward: true)
            }
        }
        if let prev = Shortcuts.prevCombo(store) {
            register(prev, action: "Previous display") { [weak self] in
                self?.displays.moveToAdjacentDisplay(forward: false)
            }
        }
        return warnings
    }
}
