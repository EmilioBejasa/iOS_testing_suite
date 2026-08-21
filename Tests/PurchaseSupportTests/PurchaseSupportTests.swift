import XCTest
import StoreKitTest
import PurchaseSupport

// iOS 15.0 for StoreKitPurchaseManager/PurchaseManaging (this package's own iOS floor
// is 13) - SKTestSession itself only needs 14.0, so the higher of the two governs.
// Under `swift test`, SKTestSession(configurationFileNamed:) looks for
// "Configuration.storekit" in the process's main bundle, which under SwiftPM's test
// runner isn't this target's own resource bundle - resolving the file via Bundle.module
// and passing its URL instead sidesteps that lookup entirely.
@available(iOS 15.0, *)
final class PurchaseSupportTests: XCTestCase {
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

    func testFetchAndPurchaseTipProduct() async throws {
        let manager = StoreKitPurchaseManager()

        let product = try await manager.product(for: "com.quotebox.tip")
        let unwrappedProduct = try XCTUnwrap(product)

        let purchased = try await manager.purchase(unwrappedProduct)
        XCTAssertTrue(purchased)
    }

    func testIsEntitledReflectsRealPurchaseUnderTestSession() async throws {
        let manager = StoreKitPurchaseManager()

        let isEntitledBeforePurchase = await manager.isEntitled(to: "com.quotebox.supporter.monthly")
        XCTAssertFalse(isEntitledBeforePurchase)

        let product = try await manager.product(for: "com.quotebox.supporter.monthly")
        let unwrappedProduct = try XCTUnwrap(product)
        let purchased = try await manager.purchase(unwrappedProduct)
        XCTAssertTrue(purchased)

        let isEntitledAfterPurchase = await manager.isEntitled(to: "com.quotebox.supporter.monthly")
        XCTAssertTrue(isEntitledAfterPurchase)
    }

    func testMockIsEntitledReturnsInjectedResult() async {
        let manager = MockPurchaseManager(isEntitledResult: true)

        let isEntitled = await manager.isEntitled(to: "com.quotebox.supporter.monthly")

        XCTAssertTrue(isEntitled)
    }
}
