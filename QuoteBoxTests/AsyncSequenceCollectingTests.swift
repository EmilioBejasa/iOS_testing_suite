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
    func testCollectsRealTransactionUpdateAfterPurchase() async throws {
        let manager = StoreKitPurchaseManager()
        let product = try await manager.product(for: "com.quotebox.tip")
        let unwrappedProduct = try XCTUnwrap(product)

        async let collected = AsyncSequenceCollecting.collect(Transaction.updates, count: 1, timeout: .seconds(5))
        _ = try await manager.purchase(unwrappedProduct)

        let transactions = try await collected
        XCTAssertEqual(transactions.first?.productID, "com.quotebox.tip")
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
