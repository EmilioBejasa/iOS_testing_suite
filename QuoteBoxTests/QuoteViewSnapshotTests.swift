import XCTest
import SnapshotTesting
@testable import QuoteBox

@MainActor
final class QuoteViewSnapshotTests: XCTestCase {
    func testQuoteViewLoaded() async {
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")
        let store = QuoteStore(apiClient: MockQuoteAPIClient(mode: .success(quote)), favoritesStore: InMemoryFavoritesStore())
        await store.fetchNewQuote()

        assertSnapshot(of: QuoteView(store: store), size: CGSize(width: 320, height: 500), named: "loaded")
    }
}
