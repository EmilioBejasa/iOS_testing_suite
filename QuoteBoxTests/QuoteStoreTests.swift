import XCTest
@testable import QuoteBox

@MainActor
final class QuoteStoreTests: XCTestCase {
    func testFetchNewQuoteSuccessUpdatesState() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let store = QuoteStore(apiClient: MockQuoteAPIClient(mode: .success(quote)), favoritesStore: InMemoryFavoritesStore())

        await store.fetchNewQuote()

        XCTAssertEqual(store.state, .loaded(quote))
    }

    func testFetchNewQuoteFailureUpdatesState() async {
        let store = QuoteStore(apiClient: MockQuoteAPIClient(mode: .failure(.requestFailed)), favoritesStore: InMemoryFavoritesStore())

        await store.fetchNewQuote()

        XCTAssertEqual(store.state, .error(APIError.requestFailed.errorDescription!))
    }

    func testToggleFavoriteAddsAndRemovesCurrentQuote() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let favoritesStore = InMemoryFavoritesStore()
        let store = QuoteStore(apiClient: MockQuoteAPIClient(mode: .success(quote)), favoritesStore: favoritesStore)
        await store.fetchNewQuote()

        XCTAssertFalse(store.isCurrentQuoteFavorited)

        store.toggleFavoriteForCurrentQuote()
        XCTAssertTrue(store.isCurrentQuoteFavorited)
        XCTAssertEqual(favoritesStore.favorites, [quote])

        store.toggleFavoriteForCurrentQuote()
        XCTAssertFalse(store.isCurrentQuoteFavorited)
        XCTAssertEqual(favoritesStore.favorites, [])
    }

    func testFavoritesLoadedFromStoreOnInit() {
        let quote = Quote(id: 1, quote: "Seed", author: "Seed Author")
        let favoritesStore = InMemoryFavoritesStore(seed: [quote])
        let store = QuoteStore(apiClient: MockQuoteAPIClient(mode: .success(quote)), favoritesStore: favoritesStore)

        XCTAssertEqual(store.favorites, [quote])
    }
}
