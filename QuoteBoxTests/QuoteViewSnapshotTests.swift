import XCTest
import PurchaseSupport
import SnapshotTesting
@testable import QuoteBox

@MainActor
final class QuoteViewSnapshotTests: XCTestCase {
    func testQuoteContentViewLoaded() {
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")

        assertSnapshot(of: QuoteContentView(quote: quote), size: CGSize(width: 300, height: 150), named: "loaded")
    }

    /// Closes the SnapshotTesting scope note: `dynamicTypeSize` shipped without a
    /// committed reference image exercising it. Uses a taller frame than the
    /// default-size snapshot above - `.accessibility3` text needs materially more
    /// vertical room to lay out both lines without clipping.
    func testQuoteContentViewLoadedAccessibility3() {
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")

        assertSnapshot(
            of: QuoteContentView(quote: quote),
            size: CGSize(width: 300, height: 400),
            dynamicTypeSize: .accessibility3,
            named: "loaded-accessibility3"
        )
    }

    /// QuoteView's `.task` (fetchNewQuote() + tipJarStore.refreshSupporterStatus())
    /// runs asynchronously after the view first appears, but this snapshot is
    /// taken synchronously right after construction - before that task gets a
    /// chance to run. This is therefore deterministically the pre-fetch
    /// `.idle`/`.loading` render (the "Loading..." ProgressView state); trying
    /// to snapshot the post-fetch loaded state instead would be racy, since
    /// nothing here awaits the view's .task.
    func testQuoteViewLoadingState() {
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(MockQuoteAPIClient.defaultQuote)),
            favoritesStore: InMemoryFavoritesStore()
        )
        let tipJarStore = TipJarStore(purchaseManager: MockPurchaseManager())

        assertSnapshot(
            of: QuoteView(store: store, tipJarStore: tipJarStore),
            size: CGSize(width: 350, height: 500),
            named: "loading"
        )
    }

    /// Unlike `testQuoteViewLoadingState` above, this awaits `fetchNewQuote()`
    /// *before* constructing `QuoteView` - `state` is already `.loaded` by the
    /// time the view is built, so its `.task` (guarded by `if case .idle =
    /// store.state`) skips re-fetching instead of racing this snapshot. The
    /// List/ScrollView layout problem that previously blocked this - see
    /// SnapshotTesting's own doc comment on `renderToPNGData` - was fixed by
    /// the UIWindow-based renderer FavoritesView's own snapshots already rely
    /// on; only the async race was still open for this specific view.
    func testQuoteViewLoadedState() async {
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore()
        )
        await store.fetchNewQuote()
        let tipJarStore = TipJarStore(purchaseManager: MockPurchaseManager())

        assertSnapshot(
            of: QuoteView(store: store, tipJarStore: tipJarStore),
            size: CGSize(width: 350, height: 700),
            named: "loaded"
        )
    }

    /// Same pre-fetch technique as testQuoteViewLoadedState, for the `.error`
    /// branch of QuoteView's content switch instead of `.loaded`.
    func testQuoteViewErrorState() async {
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .failure(.requestFailed)),
            favoritesStore: InMemoryFavoritesStore()
        )
        await store.fetchNewQuote()
        let tipJarStore = TipJarStore(purchaseManager: MockPurchaseManager())

        assertSnapshot(
            of: QuoteView(store: store, tipJarStore: tipJarStore),
            size: CGSize(width: 350, height: 500),
            named: "error"
        )
    }
}
