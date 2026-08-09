import Foundation

@MainActor
final class WeatherListViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded([WeatherListItem])
        case error(String)
    }

    @Published private(set) var state: State = .loading
    @Published var searchText: String = ""

    private let apiClient: WeatherAPIClientProtocol

    init(apiClient: WeatherAPIClientProtocol) {
        self.apiClient = apiClient
    }

    var filteredItems: [WeatherListItem] {
        guard case .loaded(let items) = state else { return [] }
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter { $0.city.localizedCaseInsensitiveContains(trimmed) }
    }

    func load() async {
        state = .loading
        do {
            let items = try await apiClient.fetchList()
            state = .loaded(items)
        } catch {
            state = .error(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
    }
}
