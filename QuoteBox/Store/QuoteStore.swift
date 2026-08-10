import Foundation
import Observation

@Observable
@MainActor
final class QuoteStore {
    enum State: Equatable {
        case idle
        case loading
        case loaded(Quote)
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var favorites: [Quote]

    private let apiClient: QuoteAPIClientProtocol
    private let favoritesStore: FavoritesStoring

    init(apiClient: QuoteAPIClientProtocol, favoritesStore: FavoritesStoring) {
        self.apiClient = apiClient
        self.favoritesStore = favoritesStore
        self.favorites = favoritesStore.loadFavorites()
    }

    var isCurrentQuoteFavorited: Bool {
        guard case .loaded(let quote) = state else { return false }
        return favorites.contains(quote)
    }

    func fetchNewQuote() async {
        state = .loading
        do {
            let quote = try await apiClient.fetchRandomQuote()
            state = .loaded(quote)
        } catch {
            state = .error((error as? LocalizedError)?.errorDescription ?? "Something went wrong.")
        }
    }

    func toggleFavoriteForCurrentQuote() {
        guard case .loaded(let quote) = state else { return }
        if let index = favorites.firstIndex(of: quote) {
            favorites.remove(at: index)
        } else {
            favorites.append(quote)
        }
        favoritesStore.save(favorites)
    }
}
