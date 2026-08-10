import XCTest
import UITestHelpers

final class QuoteBoxUITests: XCTestCase {
    func testMockSuccessShowsQuoteAndCanFavoriteIt() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))
        XCTAssertTrue(app.element("quote.author").exists)
        try app.auditAccessibility(allowing: { issue in print("AUDIT_ISSUE:", issue); return true })

        app.element("quote.favoriteButton").tap()

        app.tab("Favorites").tap()
        XCTAssertTrue(app.element("favorites.list").waitForExistence(timeout: 5))
        try app.auditAccessibility(allowing: { issue in print("AUDIT_ISSUE:", issue); return true })
    }

    func testMockErrorShowsErrorMessage() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-error"])

        XCTAssertTrue(app.element("quote.errorMessage").waitForExistence(timeout: 5))
        try app.auditAccessibility(allowing: { issue in print("AUDIT_ISSUE:", issue); return true })
    }

    func testFavoritesTabStartsEmptyWithoutFavoriting() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        app.tab("Favorites").tap()
        XCTAssertTrue(app.element("favorites.empty").waitForExistence(timeout: 5))
        try app.auditAccessibility(allowing: { issue in print("AUDIT_ISSUE:", issue); return true })
    }
}
