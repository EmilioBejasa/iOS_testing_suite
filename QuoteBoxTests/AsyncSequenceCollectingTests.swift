import XCTest
import StoreKit
import StoreKitTest
import AsyncSequenceCollecting
import PurchaseSupport

final class AsyncSequenceCollectingTests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "Configuration")
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
    /// `Transaction.updates` is a live stream, not a replay buffer -
    /// starting `collect`'s `async let` doesn't guarantee its nested task
    /// group has actually reached `for try await` over `Transaction.updates`
    /// before the next line runs, and a subscriber that hasn't started
    /// listening yet can miss an update posted in that window (a documented
    /// StoreKit gray area - see "First transaction not appearing in
    /// Transaction.updates" on Apple's developer forums). The brief sleep
    /// below gives the collector a chance to actually start listening before
    /// the purchase fires; the longer timeout gives CI's typically slower,
    /// more contended runners headroom the 5s original didn't have. Added
    /// after this test failed deterministically (3/3 retries, every device)
    /// in CI with `timedOut(collected: 0, expected: 1)`.
    func testCollectsRealTransactionUpdateAfterPurchase() async throws {
        let manager = StoreKitPurchaseManager()
        let product = try await manager.product(for: "com.quotebox.tip")
        let unwrappedProduct = try XCTUnwrap(product)

        async let collected = AsyncSequenceCollecting.collect(Transaction.updates, count: 1, timeout: .seconds(15))
        try await Task.sleep(for: .milliseconds(200))
        _ = try await manager.purchase(unwrappedProduct)

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
