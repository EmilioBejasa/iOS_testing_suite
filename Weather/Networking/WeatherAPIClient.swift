import Foundation

enum APIError: Error, Equatable, LocalizedError {
    case invalidURL
    case requestFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .requestFailed:
            return "Couldn't reach the weather service. Check your connection and try again."
        case .decodingFailed:
            return "Received an unexpected response."
        }
    }
}

protocol WeatherAPIClientProtocol {
    func fetchList() async throws -> [WeatherListItem]
    func fetchDetail(for item: WeatherListItem) async throws -> WeatherDetail
}

/// Talks to Open-Meteo (https://open-meteo.com), a free forecast API that needs no API key.
struct WeatherAPIClient: WeatherAPIClientProtocol {
    private let curatedCities: [CityCoordinate]
    private let session: URLSession

    init(session: URLSession = .shared, curatedCities: [CityCoordinate] = CityCoordinate.curated) {
        self.session = session
        self.curatedCities = curatedCities
    }

    func fetchList() async throws -> [WeatherListItem] {
        try await withThrowingTaskGroup(of: WeatherListItem.self) { group in
            for city in curatedCities {
                group.addTask {
                    let response = try await fetchForecast(latitude: city.latitude, longitude: city.longitude)
                    return WeatherListItem(
                        city: city.name,
                        country: city.country,
                        latitude: city.latitude,
                        longitude: city.longitude,
                        temperatureF: response.current.temperature2m,
                        weatherCode: response.current.weatherCode
                    )
                }
            }
            var items: [WeatherListItem] = []
            for try await item in group {
                items.append(item)
            }
            return items.sorted { $0.city < $1.city }
        }
    }

    func fetchDetail(for item: WeatherListItem) async throws -> WeatherDetail {
        let response = try await fetchForecast(latitude: item.latitude, longitude: item.longitude)
        let count = min(response.daily.time.count, response.daily.temperature2mMax.count, response.daily.temperature2mMin.count, response.daily.weatherCode.count)
        let dailyForecasts = (0..<count).map { index in
            WeatherDetail.DailyForecast(
                date: response.daily.time[index],
                maxTemperatureF: response.daily.temperature2mMax[index],
                minTemperatureF: response.daily.temperature2mMin[index],
                weatherCode: response.daily.weatherCode[index]
            )
        }
        return WeatherDetail(
            city: item.city,
            country: item.country,
            temperatureF: response.current.temperature2m,
            humidityPercent: response.current.relativeHumidity2m,
            windSpeedKmh: response.current.windSpeed10m,
            weatherCode: response.current.weatherCode,
            dailyForecasts: dailyForecasts
        )
    }

    private func fetchForecast(latitude: Double, longitude: Double) async throws -> OpenMeteoForecastResponse {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weather_code"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit")
        ]
        guard let url = components.url else { throw APIError.invalidURL }
        let (data, _) = try await load(url)
        do {
            return try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    private func load(_ url: URL) async throws -> (Data, URLResponse) {
        let result = try await session.data(from: url)
        guard let http = result.1 as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.requestFailed
        }
        return result
    }
}
