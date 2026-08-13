import StoreKit

/// Abstracts StoreKit 2 purchases so app code isn't tied to `Product`/`Transaction`
/// APIs directly. `StoreKitTest`'s `SKTestSession` is itself a local, offline
/// StoreKit simulator, so `StoreKitPurchaseManager` can be exercised for real in
/// tests without touching the real App Store — `MockPurchaseManager` exists for
/// pure app-logic unit tests that don't need to touch StoreKit at all.
@available(iOS 15.0, *)
public protocol PurchaseManaging {
    func product(for identifier: String) async throws -> Product?
    func purchase(_ product: Product) async throws -> Bool

    /// Whether the current user holds a non-revoked entitlement for
    /// `identifier` - a subscription still in its billing period, or a
    /// non-consumable/non-revoked in-app purchase.
    func isEntitled(to identifier: String) async -> Bool

    /// Starts observing `Transaction.updates` for the lifetime of the
    /// returned `Task`, calling `onUpdate` for each new or renewed
    /// transaction. Callers own the returned task and are responsible for
    /// cancelling it (e.g. in `deinit` or when the observing feature goes
    /// away) - StoreKit's `Transaction.updates` sequence never finishes on
    /// its own.
    @discardableResult
    func observeTransactionUpdates(_ onUpdate: @escaping (Transaction) -> Void) -> Task<Void, Never>
}
