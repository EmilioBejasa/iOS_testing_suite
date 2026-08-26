import XCTest
import AnalyticsLogging
import BundleInfoProviding
import PurchaseSupport
import StoreKitTest
@testable import QuoteBox

@MainActor
final class TipJarStoreTests: XCTestCase {
    /// `MockPurchaseManager`'s `storedProduct` defaults to nil, and `Product`
    /// has no public initializer to fabricate a non-nil one here (see
    /// MockPurchaseManager's own doc comment) - so this only exercises the
    /// "no product found" branch. A real .purchased/.active transition after a
    /// successful purchase needs a real Product, already covered by
    /// QuoteBoxUITests.testTipJarPurchaseResolvesAgainstWiredStoreKitConfiguration
    /// and PurchaseSupportTests. testPurchaseTipLogsAnalyticsEventOnSuccess
    /// below closes the .purchased-specific gap deterministically, using the
    /// same real-Product-via-SKTestSession approach as
    /// PurchaseSupportRealSessionTests.
    func testPurchaseTipFailsWhenNoProductFound() async {
        let store = TipJarStore(purchaseManager: MockPurchaseManager())

        await store.purchaseTip()

        XCTAssertEqual(store.state, .failed)
    }

    func testPurchaseSupporterSubscriptionFailsWhenNoProductFound() async {
        let store = TipJarStore(purchaseManager: MockPurchaseManager())

        await store.purchaseSupporterSubscription()

        XCTAssertEqual(store.supporterState, .failed)
    }

    func testRefreshSupporterStatusReflectsActiveEntitlement() async {
        let store = TipJarStore(purchaseManager: MockPurchaseManager(isEntitledResult: true))

        await store.refreshSupporterStatus()

        XCTAssertEqual(store.supporterState, .active)
    }

    func testRefreshSupporterStatusReflectsNoEntitlement() async {
        let store = TipJarStore(purchaseManager: MockPurchaseManager(isEntitledResult: false))

        await store.refreshSupporterStatus()

        XCTAssertEqual(store.supporterState, .idle)
    }

    /// Complements `PurchaseSupportRealSessionTests`' real-StoreKit lapse
    /// test at the store level: proves `TipJarStore` re-checks entitlement
    /// rather than latching onto the first `.active` result forever, using
    /// the same `MockPurchaseManager` instance's mutable `isEntitledResult`
    /// to simulate a subscription that was active and then lapsed.
    func testRefreshSupporterStatusReflectsLapseAfterPriorActiveEntitlement() async {
        let purchaseManager = MockPurchaseManager(isEntitledResult: true)
        let store = TipJarStore(purchaseManager: purchaseManager)
        await store.refreshSupporterStatus()
        XCTAssertEqual(store.supporterState, .active)

        purchaseManager.isEntitledResult = false
        await store.refreshSupporterStatus()

        XCTAssertEqual(store.supporterState, .idle)
    }
}

/// Real-`Product` variant of `TipJarStoreTests`, split into its own
/// `SKTestSession`-backed case the same way `PurchaseSupportRealSessionTests`
/// sits alongside the kit-level `PurchaseSupportTests` - runs inside the real
/// `QuoteBox.app` process via Xcode's test-bundle injection, which is what
/// gives real StoreKit product lookups a host app identity to resolve
/// against (see `PurchaseSupportRealSessionTests`'s doc comment).
@available(iOS 15.0, *)
@MainActor
final class TipJarStoreRealSessionTests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        let configURL = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "Configuration", withExtension: "storekit")
        )
        session = try SKTestSession(contentsOf: configURL)
        session.disableDialogs = true
        session.clearTransactions()
    }

    override func tearDownWithError() throws {
        session = nil
    }

    /// Closes the gap `TipJarStore.purchaseTip()`'s doc comment documents:
    /// `state == .purchased` (and therefore `"tip_purchased"` analytics
    /// logging) was previously unreachable from a deterministic unit test,
    /// since `MockPurchaseManager.product(for:)` defaults to nil and
    /// `Product` has no public initializer. Fetching a real `Product` here
    /// via `StoreKitPurchaseManager` and handing it to `MockPurchaseManager`
    /// closes that gap without needing a real purchase UI flow.
    func testPurchaseTipLogsAnalyticsEventOnSuccess() async throws {
        let realManager = StoreKitPurchaseManager()
        let product = try await realManager.product(for: "com.quotebox.tip")
        let unwrappedProduct = try XCTUnwrap(product)
        let purchaseManager = MockPurchaseManager(product: unwrappedProduct, purchaseResult: true)
        let analyticsLogger = MockAnalyticsLogger()
        let store = TipJarStore(
            purchaseManager: purchaseManager,
            analyticsLogger: analyticsLogger,
            bundleInfo: MockBundleInfoProvider()
        )

        await store.purchaseTip()

        XCTAssertEqual(store.state, .purchased)
        XCTAssertEqual(
            analyticsLogger.loggedEvents,
            [LoggedEvent(event: "tip_purchased", parameters: ["productID": "com.quotebox.tip", "appVersion": "1.0"])]
        )
    }
}
