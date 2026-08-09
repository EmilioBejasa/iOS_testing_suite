import Foundation

/// Deterministic stand-in for `WeatherAPIClient`, used by unit tests directly and by
/// the app itself under UI testing (see `WeatherApp`, which wires this in based on
/// `--mock-success` / `--mock-error` / `--mock-empty` launch arguments) so XCUITests
/// never depend on live network conditions.
final class MockWeatherAPIClient: WeatherAPIClientProtocol {
    enum Mode {
        case success
        case empty
        case failure(APIError)
    }

    private let mode: Mode
    private let listItems: [WeatherListItem]
    private let detail: WeatherDetail

    init(
        mode: Mode,
        listItems: [WeatherListItem] = MockWeatherAPIClient.defaultListItems,
        detail: WeatherDetail = MockWeatherAPIClient.defaultDetail
    ) {
        self.mode = mode
        self.listItems = listItems
        self.detail = detail
    }

    func fetchList() async throws -> [WeatherListItem] {
        switch mode {
        case .success:
            return listItems
        case .empty:
            return []
        case .failure(let error):
            throw error
        }
    }

    func fetchDetail(for item: WeatherListItem) async throws -> WeatherDetail {
        if case .failure(let error) = mode {
            throw error
        }
        return detail
    }

    static let defaultListItems: [WeatherListItem] = [
        WeatherListItem(city: "New York", country: "United States", latitude: 40.7128, longitude: -74.0060, temperatureF: 76.1, weatherCode: 1),
        WeatherListItem(city: "London", country: "United Kingdom", latitude: 51.5074, longitude: -0.1278, temperatureF: 63.0, weatherCode: 3),
        WeatherListItem(city: "Tokyo", country: "Japan", latitude: 35.6762, longitude: 139.6503, temperatureF: 84.0, weatherCode: 61),
        WeatherListItem(city: "Sydney", country: "Australia", latitude: -33.8688, longitude: 151.2093, temperatureF: 59.7, weatherCode: 0),
        WeatherListItem(city: "Cairo", country: "Egypt", latitude: 30.0444, longitude: 31.2357, temperatureF: 91.6, weatherCode: 0)
    ]

    static let defaultDetail = WeatherDetail(
        city: "New York",
        country: "United States",
        temperatureF: 76.1,
        humidityPercent: 58,
        windSpeedKmh: 12.3,
        weatherCode: 1,
        dailyForecasts: [
            .init(date: "2026-08-09", maxTemperatureF: 80.6, minTemperatureF: 66.2, weatherCode: 1),
            .init(date: "2026-08-10", maxTemperatureF: 78.8, minTemperatureF: 65.3, weatherCode: 2),
            .init(date: "2026-08-11", maxTemperatureF: 75.2, minTemperatureF: 62.6, weatherCode: 61)
        ]
    )
}
