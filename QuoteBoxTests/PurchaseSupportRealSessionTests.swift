import XCTest
import StoreKitTest
import PurchaseSupport
@testable import QuoteBox

/// Unlike `Tests/PurchaseSupportTests/PurchaseSupportTests.swift` (a bare
/// SwiftPM test bundle with no host app identity, where real StoreKit product
/// lookups return nil - see CONTRIBUTING.md's Troubleshooting table), this
/// runs inside the real `QuoteBox.app` process via Xcode's test-bundle
/// injection, giving it the host app identity StoreKit needs. Exploratory:
/// verified by CI, not assumed - if product lookup still returns nil here,
/// this moves into the kit-level target's existing skip-list treatment
/// instead (see CONTRIBUTING.md).
@available(iOS 15.0, *)
final class PurchaseSupportRealSessionTests: XCTestCase {
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

    /// Closes the gap `PurchaseSupport.isEntitled(to:)`'s doc comment already
    /// calls out: a subscription can lapse (cancellation, billing failure)
    /// after being purchased, without the purchasing code observing that
    /// renewal event directly. `expireSubscription` simulates exactly that -
    /// immediately ending the current period, as if it had already run out -
    /// without needing to wait for or accelerate real time.
    func testIsEntitledReflectsSubscriptionLapseAfterExpiration() async throws {
        let manager = StoreKitPurchaseManager()
        let productID = "com.quotebox.supporter.monthly"

        let product = try await manager.product(for: productID)
        let unwrappedProduct = try XCTUnwrap(product)
        let purchased = try await manager.purchase(unwrappedProduct)
        XCTAssertTrue(purchased)

        let isEntitledAfterPurchase = await manager.isEntitled(to: productID)
        XCTAssertTrue(isEntitledAfterPurchase)

        try session.expireSubscription(productIdentifier: productID)

        let isEntitledAfterExpiration = await manager.isEntitled(to: productID)
        XCTAssertFalse(isEntitledAfterExpiration)
    }
}
