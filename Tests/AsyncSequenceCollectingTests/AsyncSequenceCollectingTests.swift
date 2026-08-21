import XCTest
import StoreKit
import StoreKitTest
import AsyncSequenceCollecting

// iOS 16.0 for AsyncSequenceCollecting.collect (this package's own iOS floor is 13) -
// SKTestSession itself only needs 14.0, so the higher of the two governs. Under
// `swift test`, SKTestSession(configurationFileNamed:) looks for "Configuration.storekit"
// in the process's main bundle, which under SwiftPM's test runner isn't this target's own
// resource bundle - resolving the file via Bundle.module and passing its URL instead
// sidesteps that lookup entirely.
@available(iOS 16.0, *)
final class AsyncSequenceCollectingTests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        let configURL = try XCTUnwrap(Bundle.module.url(forResource: "Configuration", withExtension: "storekit"))
        session = try SKTestSession(contentsOf: configURL)
        session.disableDialogs = true
        session.clearTransactions()
    }

    override func tearDownWithError() throws {
        session = nil
    }

    /// `Transaction.updates` never finishes on its own - a bare
    /// `for try await` loop over it would hang this test forever if the
    /// purchase below somehow didn't post an update. `collect` bounds that
    /// wait instead.
    ///
    /// Uses `SKTestSession.buyProduct(identifier:options:)` rather than
    /// `StoreKitPurchaseManager.purchase()` (a direct, same-device in-app
    /// purchase) deliberately: Apple's own documentation for
    /// `Transaction.updates` says it "receives transactions that occur
    /// outside of the app" (Ask to Buy, offer code redemptions, purchases
    /// from the App Store or another device), and explicitly notes "after a
    /// successful in-app purchase on the same device, StoreKit returns the
    /// transaction through `Product.PurchaseResult.success(_:)`" instead -
    /// never through `Transaction.updates`. `SKTestSession.buyProduct`
    /// simulates exactly that external scenario, so it's the one that
    /// actually reaches `Transaction.updates`. An earlier version of this
    /// test raced a same-device `StoreKitPurchaseManager.purchase()` against
    /// `collect`, which timed out in CI deterministically (0 collected, 3/3
    /// retries, every device) even after widening the timeout to 15s and
    /// adding a pre-purchase delay - ruling out a timing race, since the
    /// actual problem was the documented contract, not timing.
    func testCollectsRealTransactionUpdateAfterExternalPurchase() async throws {
        async let collected = AsyncSequenceCollecting.collect(Transaction.updates, count: 1, timeout: .seconds(10))
        _ = try await session.buyProduct(identifier: "com.quotebox.tip")

        let transactions = try await collected
        let verification = try XCTUnwrap(transactions.first)
        guard case .verified(let transaction) = verification else {
            XCTFail("Expected a verified transaction")
            return
        }
        XCTAssertEqual(transaction.productID, "com.quotebox.tip")
    }

    func testThrowsTimeoutWhenFewerElementsArriveThanExpected() async {
        let neverEmits = AsyncStream<Int> { _ in }

        do {
            _ = try await AsyncSequenceCollecting.collect(neverEmits, count: 1, timeout: .milliseconds(200))
            XCTFail("Expected a timeout error")
        } catch AsyncSequenceCollecting.TimeoutWaitingForElements.timedOut(let collected, let expected) {
            XCTAssertEqual(collected, 0)
            XCTAssertEqual(expected, 1)
        } catch {
            XCTFail("Expected TimeoutWaitingForElements, got \(error)")
        }
    }
}
