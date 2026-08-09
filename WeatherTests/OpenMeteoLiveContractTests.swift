import XCTest
@testable import Weather

/// Hits the real Open-Meteo API instead of a stub, so an upstream response-shape
/// change surfaces here instead of as a crash in production. Deliberately excluded
/// from the default `xcodebuild test` run (see ci.yml's `-skip-testing`) so a live
/// network hiccup can never block a PR; the scheduled live-api-contract workflow
/// runs this on its own via `-only-testing`.
final class OpenMeteoLiveContractTests: XCTestCase {
    func testFetchDetailAgainstRealAPI() async throws {
        let city = CityCoordinate(name: "London", country: "United Kingdom", latitude: 51.5074, longitude: -0.1278)
        let item = WeatherListItem(city: city.name, country: city.country, latitude: city.latitude, longitude: city.longitude, temperatureF: 0, weatherCode: 0)
        let client = WeatherAPIClient(curatedCities: [city])

        let detail = try await client.fetchDetail(for: item)

        XCTAssertFalse(detail.dailyForecasts.isEmpty)
        XCTAssertTrue((-100...150).contains(detail.temperatureF), "Temperature out of plausible range: \(detail.temperatureF)")
        XCTAssertTrue((0...100).contains(detail.humidityPercent), "Humidity out of plausible range: \(detail.humidityPercent)")
    }

    func testFetchListAgainstRealAPI() async throws {
        let client = WeatherAPIClient()
        let items = try await client.fetchList()
        XCTAssertEqual(items.count, CityCoordinate.curated.count)
    }
}
