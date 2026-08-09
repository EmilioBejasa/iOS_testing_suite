import XCTest

extension XCUIApplication {
    /// SwiftUI doesn't always back an identifier with the XCUIElement type you'd
    /// expect (e.g. `.accessibilityIdentifier` on a `List` can surface as a table,
    /// collection view, or plain element depending on OS version), so look for the
    /// identifier across every element type instead of guessing one.
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func launched(withArguments arguments: [String]) -> XCUIApplication {
        launchArguments = arguments
        launch()
        return self
    }
}
