import XCTest

public extension XCTestCase {
    /// Launches a fresh `XCUIApplication` inside `measure`, collecting XCTest's
    /// built-in `XCTApplicationLaunchMetric`. Deliberately asserts no fixed
    /// pass/fail duration: `measure`'s baseline comparison is tied to a specific
    /// device/Xcode version, which doesn't travel across a CI matrix of ephemeral,
    /// variable-hardware runners — a hardcoded ceiling would flag hardware noise,
    /// not real regressions. The numbers still land in the `.xcresult` (already
    /// uploaded as a CI artifact by `reusable-test.yml`) for anyone tracking the
    /// trend over time.
    func measureLaunch(withArguments arguments: [String] = []) {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            _ = XCUIApplication().launched(withArguments: arguments)
        }
    }
}
