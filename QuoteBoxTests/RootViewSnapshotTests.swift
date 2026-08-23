import XCTest
import PurchaseSupport
import SnapshotTesting
import SwiftUI
@testable import QuoteBox

@MainActor
final class RootViewSnapshotTests: XCTestCase {
    /// Same .task-timing consideration as
    /// QuoteViewSnapshotTests.testQuoteViewLoadingState - RootView's first tab
    /// embeds QuoteView, so this also deterministically captures the pre-task
    /// loading render, not the post-fetch loaded state. The Debug tab (guarded
    /// by `#if DEBUG` in RootView) is present here since tests build under the
    /// same Debug configuration that guard checks - not a source of
    /// nondeterminism, just worth noting.
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
}
