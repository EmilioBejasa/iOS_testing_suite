import XCTest

final class WeatherDetailUITests: XCTestCase {
    func testTappingCityShowsDetailWeather() {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        let row = app.element("weatherRow.New York")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        XCTAssertTrue(app.element("weatherDetail.temperature").waitForExistence(timeout: 5))
        XCTAssertTrue(app.element("weatherDetail.condition").exists)
        XCTAssertTrue(app.element("weatherDetail.measurements").exists)
        XCTAssertTrue(app.element("weatherDetail.dailyForecast").exists)
    }
}
