import StoreKit

/// `Product` has no public initializer, so unlike `MockQuoteAPIClient`/
/// `MockReminderScheduler`, this can't fabricate a product from nothing — it
/// holds a real `Product` (typically fetched once via a real
/// `StoreKitPurchaseManager` under `SKTestSession`) and fakes only the purchase
/// outcome, for app-logic tests that don't need to re-exercise the whole
/// fetch-then-purchase flow every time.
@available(iOS 15.0, *)
public final class MockPurchaseManager: PurchaseManaging {
    public var storedProduct: Product?
    public var purchaseResult: Bool

    public init(product: Product? = nil, purchaseResult: Bool = true) {
        self.storedProduct = product
        self.purchaseResult = purchaseResult
    }

    public func product(for identifier: String) async throws -> Product? {
        storedProduct
    }

    public func purchase(_ product: Product) async throws -> Bool {
        purchaseResult
    }
}
