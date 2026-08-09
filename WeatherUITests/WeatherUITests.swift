import XCTest

final class WeatherUITests: XCTestCase {
    func testListLoadsWithMockSuccess() {
        let app = XCUIApplication()
        app.launchArguments = ["--mock-success"]
        app.launch()

        XCTAssertTrue(app.otherElements["weatherList.list"].waitForExistence(timeout: 5))
    }
}
