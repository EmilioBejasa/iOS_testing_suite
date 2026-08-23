import XCTest
import PurchaseSupport
@testable import QuoteBox

@MainActor
final class TipJarStoreTests: XCTestCase {
    /// `MockPurchaseManager`'s `storedProduct` defaults to nil, and `Product`
    /// has no public initializer to fabricate a non-nil one here (see
    /// MockPurchaseManager's own doc comment) - so this only exercises the
    /// "no product found" branch. A real .purchased/.active transition after a
    /// successful purchase needs a real Product, already covered by
    /// QuoteBoxUITests.testTipJarPurchaseResolvesAgainstWiredStoreKitConfiguration
    /// and PurchaseSupportTests.
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
}
