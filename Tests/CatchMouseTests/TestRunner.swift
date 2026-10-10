import Foundation

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, line: UInt = #line) throws {
    if actual != expected { throw TestFailure(description: "line \(line): expected \(expected), got \(actual)") }
}
func expectNil<T>(_ value: T?, line: UInt = #line) throws {
    if let value { throw TestFailure(description: "line \(line): expected nil, got \(value)") }
}
func expectFalse(_ value: Bool, line: UInt = #line) throws {
    if value { throw TestFailure(description: "line \(line): expected false") }
}

@main
struct TestRunner {
    static func main() throws {
        let tests = ShortcutTests()
        let cases: [(String, () throws -> Void)] = [
            ("new install defaults", tests.testNewInstallUsesPositionalDefaults),
            ("monitor identity survives reordering", tests.testCustomShortcutFollowsMonitorAfterReorderingAndRelaunch),
            ("cleared display shortcut persists", tests.testClearedShortcutStaysDisabledAfterRelaunch),
            ("cleared cycle shortcuts persist", tests.testClearedCycleShortcutsStayDisabled),
            ("reset restores defaults", tests.testResetRestoresAllDefaults),
            ("malformed preferences", tests.testMalformedPreferencesFallBackToDefaults),
            ("existing native v1 preferences", tests.testExistingV1PreferencesRemainReadable),
            ("invalid key codes", tests.testInvalidStoredKeyCodesCannotCrashRegistration),
            ("CLI argument validation", tests.testCLIRejectsMissingAndExtraArguments),
        ]
        for (name, test) in cases {
            tests.setUp()
            defer { tests.tearDown() }
            try test()
            print("PASS: \(name)")
        }
        print("\(cases.count) regression tests passed.")
    }
}
