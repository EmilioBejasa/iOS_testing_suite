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

    /// Thin, discoverable wrapper around XCTest's built-in accessibility audit so it
    /// doesn't have to be rediscovered per app. `allowing` lets a test allow-list a
    /// specific known issue (return `true` to treat it as handled) while still
    /// failing on everything else.
    @available(iOS 17.0, *)
    func auditAccessibility(
        _ types: XCUIAccessibilityAuditType = .all,
        allowing isKnownIssue: @escaping (XCUIAccessibilityAuditIssue) -> Bool = { _ in false }
    ) throws {
        try performAccessibilityAudit(for: types, isKnownIssue)
    }

    @discardableResult
    func launched(withArguments arguments: [String]) -> XCUIApplication {
        launchArguments = arguments
        launch()
        return self
    }
}
