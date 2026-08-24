import XCTest
import PurchaseSupport
import SnapshotTesting
import SwiftUI
@testable import QuoteBox

@MainActor
final class RootViewSnapshotTests: XCTestCase {
    /// RootView's first tab embeds QuoteView, whose `.task`
    /// (fetchNewQuote() + tipJarStore.refreshSupporterStatus()) runs
    /// asynchronously after the view first appears - this snapshot is taken
    /// synchronously right after construction, before that task gets a
    /// chance to run, so it deterministically captures the pre-fetch
    /// `.idle`/`.loading` render. The Debug tab (guarded by `#if DEBUG` in
    /// RootView) is present here since tests build under the same Debug
    /// configuration that guard checks - not a source of nondeterminism,
    /// just worth noting.
    func testRootViewInitialQuoteTab() {
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(MockQuoteAPIClient.defaultQuote)),
            favoritesStore: InMemoryFavoritesStore()
        )
        let tipJarStore = TipJarStore(purchaseManager: MockPurchaseManager())

        assertSnapshot(
            of: RootView(
                store: store,
                tipJarStore: tipJarStore,
                launchCount: 1,
                didRequestReviewThisLaunch: false,
                route: .constant(nil)
            ),
            size: CGSize(width: 390, height: 700),
            named: "quoteTab"
        )
    }

    /// Same pre-fetch technique QuoteViewSnapshotTests.testQuoteViewLoadedState
    /// uses - awaiting fetchNewQuote() before constructing RootView means
    /// `state` is already `.loaded`, so the `.task` inside the embedded
    /// QuoteView skips re-fetching instead of racing this snapshot.
    func testRootViewQuoteTabLoaded() async {
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore()
        )
        await store.fetchNewQuote()
        let tipJarStore = TipJarStore(purchaseManager: MockPurchaseManager())

        assertSnapshot(
            of: RootView(
                store: store,
                tipJarStore: tipJarStore,
                launchCount: 1,
                didRequestReviewThisLaunch: false,
                route: .constant(nil)
            ),
            size: CGSize(width: 390, height: 700),
            named: "quoteTabLoaded"
        )
    }

    /// RootView's init switches `selectedTab` to `.favorites` up front when
    /// `route.wrappedValue` is already `.favorites` - the same mechanism a
    /// real `--deep-link`/`--universal-link` launch drives, exercised here
    /// directly instead of needing a full app launch.
    func testRootViewFavoritesTabSeeded() {
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")
        let secondQuote = Quote(id: 2, quote: "Stay hungry, stay foolish.", author: "Steve Jobs")
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(seed: [quote, secondQuote])
        )
        let tipJarStore = TipJarStore(purchaseManager: MockPurchaseManager())

        assertSnapshot(
            of: RootView(
                store: store,
                tipJarStore: tipJarStore,
                launchCount: 1,
                didRequestReviewThisLaunch: false,
                route: .constant(.favorites)
            ),
            size: CGSize(width: 390, height: 700),
            named: "favoritesTab"
        )
    }
}
