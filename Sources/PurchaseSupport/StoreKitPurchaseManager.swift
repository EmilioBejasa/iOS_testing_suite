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
}
