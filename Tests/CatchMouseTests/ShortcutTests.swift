import Carbon.HIToolbox
import Foundation

final class ShortcutTests {
    private var suite: String!
    private var defaults: UserDefaults!
    private var store: HotKeyStore!
    private let custom = KeyCombo(keyCode: kVK_ANSI_1, carbonModifiers: cmdKey)

    func setUp() {
        suite = "CatchMouseTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        store = HotKeyStore(defaults: defaults)
    }

    func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testNewInstallUsesPositionalDefaults() throws {
        try expectEqual(Shortcuts.jumpCombo(index: 0, displayKey: "a", store: store), Shortcuts.defaultJump[0])
        try expectEqual(Shortcuts.nextCombo(store), Shortcuts.defaultNext)
        try expectEqual(Shortcuts.prevCombo(store), Shortcuts.defaultPrev)
        try expectNil(Shortcuts.jumpCombo(index: 3, displayKey: "d", store: store))
        try expectNil(Shortcuts.jumpCombo(index: -1, displayKey: "a", store: store))
    }

    func testCustomShortcutFollowsMonitorAfterReorderingAndRelaunch() throws {
        store.setBinding(custom, forDisplay: "monitor-uuid")
        let relaunched = HotKeyStore(defaults: defaults)
        try expectEqual(Shortcuts.jumpCombo(index: 5, displayKey: "monitor-uuid", store: relaunched), custom)
        try expectEqual(Shortcuts.jumpCombo(index: 0, displayKey: "other-monitor", store: relaunched), Shortcuts.defaultJump[0])
    }

    func testClearedShortcutStaysDisabledAfterRelaunch() throws {
        store.setBinding(nil, forDisplay: "monitor-uuid")
        let relaunched = HotKeyStore(defaults: defaults)
        try expectNil(Shortcuts.jumpCombo(index: 0, displayKey: "monitor-uuid", store: relaunched))
        relaunched.setBinding(custom, forDisplay: "monitor-uuid")
        try expectEqual(Shortcuts.jumpCombo(index: 0, displayKey: "monitor-uuid", store: store), custom)
    }

    func testClearedCycleShortcutsStayDisabled() throws {
        store.setNext(nil)
        store.setPrev(nil)
        let relaunched = HotKeyStore(defaults: defaults)
        try expectNil(Shortcuts.nextCombo(relaunched))
        try expectNil(Shortcuts.prevCombo(relaunched))
        relaunched.setNext(custom)
        try expectEqual(Shortcuts.nextCombo(store), custom)
        try expectNil(Shortcuts.prevCombo(store))
    }

    func testResetRestoresAllDefaults() throws {
        store.setBinding(nil, forDisplay: "a")
        store.setBinding(custom, forDisplay: "b")
        store.setNext(nil)
        store.setPrev(custom)
        store.resetAll()
        try expectEqual(Shortcuts.jumpCombo(index: 0, displayKey: "a", store: store), Shortcuts.defaultJump[0])
        try expectEqual(Shortcuts.jumpCombo(index: 1, displayKey: "b", store: store), Shortcuts.defaultJump[1])
        try expectEqual(Shortcuts.nextCombo(store), Shortcuts.defaultNext)
        try expectEqual(Shortcuts.prevCombo(store), Shortcuts.defaultPrev)
    }

    func testMalformedPreferencesFallBackToDefaults() throws {
        defaults.set(Data("broken json".utf8), forKey: "perDisplayBindings.v1")
        defaults.set(Data("broken json".utf8), forKey: "nextBinding.v1")
        try expectEqual(Shortcuts.jumpCombo(index: 0, displayKey: "a", store: store), Shortcuts.defaultJump[0])
        try expectEqual(Shortcuts.nextCombo(store), Shortcuts.defaultNext)
    }

    func testExistingV1PreferencesRemainReadable() throws {
        let oldData = try JSONEncoder().encode(["a": custom])
        defaults.set(oldData, forKey: "perDisplayBindings.v1")
        try expectEqual(Shortcuts.jumpCombo(index: 0, displayKey: "a", store: store), custom)
    }

    func testInvalidStoredKeyCodesCannotCrashRegistration() throws {
        let invalid = KeyCombo(keyCode: -1, carbonModifiers: cmdKey)
        defaults.set(try JSONEncoder().encode(["a": invalid]), forKey: "perDisplayBindings.v1")
        defaults.set(try JSONEncoder().encode(invalid), forKey: "nextBinding.v1")
        try expectEqual(Shortcuts.jumpCombo(index: 0, displayKey: "a", store: store), Shortcuts.defaultJump[0])
        try expectEqual(Shortcuts.nextCombo(store), Shortcuts.defaultNext)
        try expectFalse(KeyCombo(keyCode: 0, carbonModifiers: -1).isValid)
        try expectFalse(KeyCombo(keyCode: 0, carbonModifiers: shiftKey).isValid)
    }

    func testCLIRejectsMissingAndExtraArguments() throws {
        try expectEqual(runCLI(arguments: []), 2)
        try expectEqual(runCLI(arguments: ["--move"]), 2)
        try expectEqual(runCLI(arguments: ["--version", "extra"]), 2)
        try expectEqual(runCLI(arguments: ["--move", "1", "extra"]), 2)
        try expectEqual(runCLI(arguments: ["--move", "not-a-number"]), 2)
        try expectEqual(runCLI(arguments: ["--move", "0"]), 2)
    }
}
