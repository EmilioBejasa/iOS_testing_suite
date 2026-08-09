import XCTest
@testable import Weather

/// Intercepts every request so `WeatherAPIClient` (the real network client, not the
/// mock) can be tested against canned JSON without touching the network.
private final class StubURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class WeatherAPIClientTests: XCTestCase {
    private var session: URLSession!
    private let city = CityCoordinate(name: "Testville", country: "Testland", latitude: 1.0, longitude: 2.0)

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        session = URLSession(configuration: configuration)
    }

    override func tearDown() {
        StubURLProtocol.handler = nil
        session = nil
        super.tearDown()
    }

    func testFetchDetailDecodesForecastIntoWeatherDetail() async throws {
        let json = """
        {
          "current": { "temperature_2m": 72.5, "relative_humidity_2m": 55, "wind_speed_10m": 8.1, "weather_code": 2 },
          "daily": {
            "time": ["2026-08-09", "2026-08-10"],
            "temperature_2m_max": [80.0, 78.5],
            "temperature_2m_min": [65.0, 64.0],
            "weather_code": [1, 3]
          }
        }
        """.data(using: .utf8)!

        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.host, "api.open-meteo.com")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let client = WeatherAPIClient(session: session, curatedCities: [city])
        let item = WeatherListItem(city: city.name, country: city.country, latitude: city.latitude, longitude: city.longitude, temperatureF: 0, weatherCode: 0)

        let detail = try await client.fetchDetail(for: item)

        XCTAssertEqual(detail.city, "Testville")
        XCTAssertEqual(detail.temperatureF, 72.5)
        XCTAssertEqual(detail.humidityPercent, 55)
        XCTAssertEqual(detail.windSpeedKmh, 8.1)
        XCTAssertEqual(detail.dailyForecasts.count, 2)
        XCTAssertEqual(detail.dailyForecasts[0].date, "2026-08-09")
        XCTAssertEqual(detail.dailyForecasts[0].maxTemperatureF, 80.0)
    }

    func testFetchListThrowsRequestFailedOnServerError() async {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let client = WeatherAPIClient(session: session, curatedCities: [city])

        do {
            _ = try await client.fetchList()
            XCTFail("Expected fetchList to throw")
        } catch let error as APIError {
            XCTAssertEqual(error, .requestFailed)
        } catch {
            XCTFail("Expected APIError.requestFailed, got \(error)")
        }
    }

    func testFetchListThrowsDecodingFailedOnMalformedJSON() async {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "not json".data(using: .utf8)!)
        }

        let client = WeatherAPIClient(session: session, curatedCities: [city])

        do {
            _ = try await client.fetchList()
            XCTFail("Expected fetchList to throw")
        } catch let error as APIError {
            XCTAssertEqual(error, .decodingFailed)
        } catch {
            XCTFail("Expected APIError.decodingFailed, got \(error)")
        }
    }
}
