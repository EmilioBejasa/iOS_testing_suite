import Foundation

/// Fixed set of cities the list view surfaces; each is refreshed against Open-Meteo
/// on load, so the "list" endpoint is a real network round trip per city.
struct CityCoordinate: Equatable {
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double

    static let curated: [CityCoordinate] = [
        .init(name: "New York", country: "United States", latitude: 40.7128, longitude: -74.0060),
        .init(name: "London", country: "United Kingdom", latitude: 51.5074, longitude: -0.1278),
        .init(name: "Tokyo", country: "Japan", latitude: 35.6762, longitude: 139.6503),
        .init(name: "Sydney", country: "Australia", latitude: -33.8688, longitude: 151.2093),
        .init(name: "Cairo", country: "Egypt", latitude: 30.0444, longitude: 31.2357),
        .init(name: "Rio de Janeiro", country: "Brazil", latitude: -22.9068, longitude: -43.1729),
        .init(name: "Mumbai", country: "India", latitude: 19.0760, longitude: 72.8777),
        .init(name: "Cape Town", country: "South Africa", latitude: -33.9249, longitude: 18.4241)
    ]
}

struct WeatherListItem: Identifiable, Hashable {
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    let temperatureF: Double
    let weatherCode: Int

    var id: String { city }
}

struct WeatherDetail: Equatable {
    let city: String
    let country: String
    let temperatureF: Double
    let humidityPercent: Int
    let windSpeedKmh: Double
    let weatherCode: Int
    let dailyForecasts: [DailyForecast]

    struct DailyForecast: Equatable, Identifiable {
        let date: String
        let maxTemperatureF: Double
        let minTemperatureF: Double
        let weatherCode: Int

        var id: String { date }
    }
}

/// Decodes Open-Meteo's forecast response shape directly:
/// https://api.open-meteo.com/v1/forecast?latitude=..&longitude=..&current=...&daily=...
struct OpenMeteoForecastResponse: Decodable {
    let current: Current
    let daily: Daily

    struct Current: Decodable {
        let temperature2m: Double
        let relativeHumidity2m: Int
        let windSpeed10m: Double
        let weatherCode: Int

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case relativeHumidity2m = "relative_humidity_2m"
            case windSpeed10m = "wind_speed_10m"
            case weatherCode = "weather_code"
        }
    }

    struct Daily: Decodable {
        let time: [String]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let weatherCode: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case weatherCode = "weather_code"
        }
    }
}

/// Maps WMO weather codes (used by Open-Meteo) to a human label and SF Symbol.
/// https://open-meteo.com/en/docs#weathervariables
enum WeatherCondition {
    static func description(for code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1: return "Mainly clear"
        case 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow grains"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm with hail"
        default: return "Unknown"
        }
    }

    static func symbolName(for code: Int) -> String {
        switch code {
        case 0: return "sun.max"
        case 1, 2: return "cloud.sun"
        case 3: return "cloud"
        case 45, 48: return "cloud.fog"
        case 51, 53, 55, 56, 57: return "cloud.drizzle"
        case 61, 63, 65, 66, 67, 80, 81, 82: return "cloud.rain"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow"
        case 95, 96, 99: return "cloud.bolt.rain"
        default: return "questionmark"
        }
    }
}
