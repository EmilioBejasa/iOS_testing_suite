import XCTest
import SnapshotTesting
@testable import QuoteBox

@MainActor
final class FavoritesViewSnapshotTests: XCTestCase {
    func testFavoritesViewWithSeededFavorites() {
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")
        let secondQuote = Quote(id: 2, quote: "Stay hungry, stay foolish.", author: "Steve Jobs")
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(seed: [quote, secondQuote])
        )

        assertSnapshot(of: FavoritesView(store: store), size: CGSize(width: 350, height: 500), named: "seeded")
    }

    /// Distinct render path from the seeded case above: FavoritesView.body
    /// switches on `store.favorites.isEmpty` to show the "No favorites yet"
    /// text instead of the List - both branches are worth a reference image.
    func testFavoritesViewEmptyState() {
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore()
        )

        assertSnapshot(of: FavoritesView(store: store), size: CGSize(width: 350, height: 500), named: "empty")
    }
}
