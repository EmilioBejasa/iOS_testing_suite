import XCTest
import StoreKitTest
import PurchaseSupport

final class PurchaseSupportTests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "Configuration")
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
