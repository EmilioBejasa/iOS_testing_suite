import SwiftUI

@main
struct WeatherApp: App {
    private let apiClient: WeatherAPIClientProtocol

    init() {
        apiClient = Self.makeAPIClient()
    }

    var body: some Scene {
        WindowGroup {
            WeatherListView(apiClient: apiClient)
        }
    }

    /// UI tests launch the app with one of these arguments (see WeatherListUITests /
    /// WeatherDetailUITests) so behavior is deterministic instead of depending on the
    /// live Open-Meteo network response.
    private static func makeAPIClient() -> WeatherAPIClientProtocol {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--mock-error") {
            return MockWeatherAPIClient(mode: .failure(.requestFailed))
        } else if arguments.contains("--mock-empty") {
            return MockWeatherAPIClient(mode: .empty)
        } else if arguments.contains("--mock-success") {
            return MockWeatherAPIClient(mode: .success)
        } else {
            return WeatherAPIClient()
        }
    }
}
