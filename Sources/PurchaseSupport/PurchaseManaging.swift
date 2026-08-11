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
}
