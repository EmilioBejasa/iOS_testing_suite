import Foundation

@MainActor
final class WeatherDetailViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded(WeatherDetail)
        case error(String)
    }

    @Published private(set) var state: State = .loading

    private let listItem: WeatherListItem
    private let apiClient: WeatherAPIClientProtocol

    init(listItem: WeatherListItem, apiClient: WeatherAPIClientProtocol) {
        self.listItem = listItem
        self.apiClient = apiClient
    }

    func load() async {
        state = .loading
        do {
            let detail = try await apiClient.fetchDetail(for: listItem)
            state = .loaded(detail)
        } catch {
            state = .error((error as? LocalizedError)?.errorDescription ?? "Something went wrong.")
        }
    }
}
