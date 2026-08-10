import XCTest

public extension XCUIApplication {
    /// SwiftUI doesn't always back an identifier with the XCUIElement type you'd
    /// expect (e.g. `.accessibilityIdentifier` on a `List` can surface as a table,
    /// collection view, or plain element depending on OS version), so look for the
    /// identifier across every element type instead of guessing one.
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// iPadOS 18's floating tab bar backs its items with a private element type
    /// XCTest can't reliably classify as `.tabBar`/`.button` (it logs an
    /// "Automation type mismatch" and `tabBars` comes back empty), while iPhone's
    /// classic tab bar works fine with type-scoped queries. Search by label across
    /// every element type instead so the same lookup works on both.
    func tab(_ label: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    @discardableResult
    func launched(withArguments arguments: [String]) -> XCUIApplication {
        launchArguments = arguments
        launch()
        return self
    }
}
