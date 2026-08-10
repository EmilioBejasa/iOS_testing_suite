import SwiftUI

@main
struct QuoteBoxApp: App {
    private let store: QuoteStore

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let apiClient: QuoteAPIClientProtocol
        let favoritesStore: FavoritesStoring

        if arguments.contains("--mock-error") {
            apiClient = MockQuoteAPIClient(mode: .failure(.requestFailed))
            favoritesStore = InMemoryFavoritesStore()
        } else if arguments.contains("--mock-success") {
            apiClient = MockQuoteAPIClient(mode: .success(MockQuoteAPIClient.defaultQuote))
            favoritesStore = InMemoryFavoritesStore()
        } else {
            apiClient = QuoteAPIClient()
            favoritesStore = UserDefaultsFavoritesStore()
        }

        store = QuoteStore(apiClient: apiClient, favoritesStore: favoritesStore)
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
    }
}
