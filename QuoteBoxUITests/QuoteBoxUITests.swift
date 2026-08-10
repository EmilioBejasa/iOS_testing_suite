import XCTest
import UITestHelpers

final class QuoteBoxUITests: XCTestCase {
    func testMockSuccessShowsQuoteAndCanFavoriteIt() {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))
        XCTAssertTrue(app.element("quote.author").exists)

        app.element("quote.favoriteButton").tap()

        app.tabBars.buttons["Favorites"].tap()
        XCTAssertTrue(app.element("favorites.list").waitForExistence(timeout: 5))
    }

    func testMockErrorShowsErrorMessage() {
        let app = XCUIApplication().launched(withArguments: ["--mock-error"])

        XCTAssertTrue(app.element("quote.errorMessage").waitForExistence(timeout: 5))
    }

    func testFavoritesTabStartsEmptyWithoutFavoriting() {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        app.tabBars.buttons["Favorites"].tap()
        XCTAssertTrue(app.element("favorites.empty").waitForExistence(timeout: 5))
    }
}
