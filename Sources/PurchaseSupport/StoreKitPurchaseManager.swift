import StoreKit

/// Real implementation, wrapping `Product.products(for:)` / `Product.purchase()` /
/// `Transaction` verification. StoreKit 2's APIs are already async-native, so
/// unlike `SystemReminderScheduler`/`SystemLocationAuthorizer` there's no
/// delegate-to-async bridging needed here.
@available(iOS 15.0, *)
public struct StoreKitPurchaseManager: PurchaseManaging {
    public init() {}

    public func product(for identifier: String) async throws -> Product? {
        try await Product.products(for: [identifier]).first
    }

    public func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    public func isEntitled(to identifier: String) async -> Bool {
        for await verification in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verification else { continue }
            if transaction.productID == identifier && transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }

    @discardableResult
    public func observeTransactionUpdates(_ onUpdate: @escaping (Transaction) -> Void) -> Task<Void, Never> {
        Task.detached {
            for await verification in Transaction.updates {
                guard case .verified(let transaction) = verification else { continue }
                onUpdate(transaction)
            }
        }
    }
}
