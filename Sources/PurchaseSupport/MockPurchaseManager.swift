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
    public var isEntitledResult: Bool
    private var transactionUpdateHandlers: [(Transaction) -> Void] = []

    public init(product: Product? = nil, purchaseResult: Bool = true, isEntitledResult: Bool = false) {
        self.storedProduct = product
        self.purchaseResult = purchaseResult
        self.isEntitledResult = isEntitledResult
    }

    public func product(for identifier: String) async throws -> Product? {
        storedProduct
    }

    public func purchase(_ product: Product) async throws -> Bool {
        purchaseResult
    }

    public func isEntitled(to identifier: String) async -> Bool {
        isEntitledResult
    }

    @discardableResult
    public func observeTransactionUpdates(_ onUpdate: @escaping (Transaction) -> Void) -> Task<Void, Never> {
        transactionUpdateHandlers.append(onUpdate)
        return Task {}
    }

    /// Test hook: simulates StoreKit delivering `transaction` to every
    /// handler registered via `observeTransactionUpdates`, without a real
    /// `Transaction.updates` sequence to drive from.
    public func simulateTransactionUpdate(_ transaction: Transaction) {
        for handler in transactionUpdateHandlers {
            handler(transaction)
        }
    }
}
