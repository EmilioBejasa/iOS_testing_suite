import XCTest
@testable import Weather

final class WeatherTests: XCTestCase {
    func testMockClientReturnsConfiguredList() async throws {
        let client = MockWeatherAPIClient(mode: .success)
        let items = try await client.fetchList()
        XCTAssertEqual(items, MockWeatherAPIClient.defaultListItems)
    }
}
