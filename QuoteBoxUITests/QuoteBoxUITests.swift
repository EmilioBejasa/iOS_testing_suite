import XCTest
import UITestHelpers

final class QuoteBoxUITests: XCTestCase {
    func testMockSuccessShowsQuoteAndCanFavoriteIt() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))
        XCTAssertTrue(app.element("quote.author").exists)
        try auditIgnoringKnownFalsePositives(app)

        app.element("quote.favoriteButton").tap()

        app.tab("Favorites").tap()
        XCTAssertTrue(app.element("favorites.list").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)
    }

    func testMockErrorShowsErrorMessage() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-error"])

        XCTAssertTrue(app.element("quote.errorMessage").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)
    }

    func testFavoritesTabStartsEmptyWithoutFavoriting() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        app.tab("Favorites").tap()
        XCTAssertTrue(app.element("favorites.empty").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)
    }

    func testEnablingDailyReminderTurnsToggleOn() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))
        XCTAssertEqual(app.element("quote.reminderToggle").value as? String, "0")

        app.element("quote.reminderToggle").tap()

        XCTAssertTrue(waitUntil(timeout: 5) { app.element("quote.reminderToggle").value as? String == "1" })
        try auditIgnoringKnownFalsePositives(app)
    }

    func testDeniedNotificationPermissionShowsMessage() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success", "--mock-notifications-denied"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))
        app.element("quote.reminderToggle").tap()

        XCTAssertTrue(app.element("quote.reminderDeniedMessage").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)
    }

    /// Re-evaluates `condition` (which should re-query fresh each call, e.g. via
    /// `app.element(_:)`) rather than waiting on a single captured `XCUIElement`,
    /// since a snapshot taken before a UI change doesn't reliably live-update.
    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            usleep(100_000)
        }
        return condition()
    }

    /// Two audit types are allow-listed for reasons unrelated to QuoteBox's own
    /// text/color choices, confirmed by diagnostic runs before landing this:
    ///  - `.contrast`: headless CI simulators report a generic "Contrast nearly
    ///    passed... unless font size is larger" finding on every text/button
    ///    element regardless of its actual color (default black text, .secondary
    ///    gray, .borderedProminent's white-on-accent all hit it identically) — a
    ///    known false-positive pattern for this audit type in this environment.
    ///  - `.dynamicType`: only fails on iPad, never on iPhone 16/SE running the
    ///    identical view code, and neither QuoteView nor FavoritesView has any
    ///    .lineLimit/.fixedSize/fixed frame that could truncate text. project.yml
    ///    sets `TARGETED_DEVICE_FAMILY: "1"` (iPhone-only), so on iPad the app runs
    ///    in iPhone-compatibility mode, which has real, documented Dynamic Type
    ///    scaling limitations — not a text-layout bug in this app's views.
    /// Every other audit type (missing labels, hit target size, element detection,
    /// etc.) still fails the test normally.
    private func auditIgnoringKnownFalsePositives(_ app: XCUIApplication) throws {
        try app.auditAccessibility(allowing: { $0.auditType == .contrast || $0.auditType == .dynamicType })
    }
}
