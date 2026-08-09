import XCTest
import UITestHelpers

final class WeatherListUITests: XCTestCase {
    func testMockSuccessShowsCityList() {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("weatherList.list").waitForExistence(timeout: 5))
        XCTAssertTrue(app.element("weatherRow.New York").exists)
        XCTAssertTrue(app.element("weatherRow.London").exists)
    }

    func testMockEmptyShowsNoResultsMessage() {
        let app = XCUIApplication().launched(withArguments: ["--mock-empty"])

        XCTAssertTrue(app.element("weatherList.noResults").waitForExistence(timeout: 5))
    }

    func testMockErrorShowsErrorAndRetryStaysOnError() {
        let app = XCUIApplication().launched(withArguments: ["--mock-error"])

        let errorMessage = app.element("weatherList.errorMessage")
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))

        app.element("weatherList.retryButton").tap()
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }

    func testSearchFiltersCityList() {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("weatherList.list").waitForExistence(timeout: 5))

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("London")

        XCTAssertTrue(app.element("weatherRow.London").waitForExistence(timeout: 5))
        XCTAssertFalse(app.element("weatherRow.New York").exists)
    }
}
