import XCTest
@testable import Weather

final class OpenMeteoForecastResponseTests: XCTestCase {
    func testDecodesCurrentAndDailyFields() throws {
        let json = """
        {
          "current": {
            "temperature_2m": 72.5,
            "relative_humidity_2m": 55,
            "wind_speed_10m": 8.1,
            "weather_code": 2
          },
          "daily": {
            "time": ["2026-08-09", "2026-08-10"],
            "temperature_2m_max": [80.0, 78.5],
            "temperature_2m_min": [65.0, 64.0],
            "weather_code": [1, 3]
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: json)

        XCTAssertEqual(response.current.temperature2m, 72.5)
        XCTAssertEqual(response.current.relativeHumidity2m, 55)
        XCTAssertEqual(response.current.windSpeed10m, 8.1)
        XCTAssertEqual(response.current.weatherCode, 2)
        XCTAssertEqual(response.daily.time, ["2026-08-09", "2026-08-10"])
        XCTAssertEqual(response.daily.temperature2mMax, [80.0, 78.5])
        XCTAssertEqual(response.daily.temperature2mMin, [65.0, 64.0])
        XCTAssertEqual(response.daily.weatherCode, [1, 3])
    }
}
