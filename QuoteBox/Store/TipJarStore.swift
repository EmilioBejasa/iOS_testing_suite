import Observation
import PurchaseSupport

@Observable
@MainActor
final class TipJarStore {
    enum State: Equatable {
        case idle
        case purchasing
        case purchased
        case failed
    }

    enum SupporterState: Equatable {
        case idle
        case purchasing
        case active
        case failed
    }

    private(set) var state: State = .idle
    private(set) var supporterState: SupporterState = .idle

    private let purchaseManager: PurchaseManaging
    private let productIdentifier = "com.quotebox.tip"
    private let supporterProductIdentifier = "com.quotebox.supporter.monthly"

    init(purchaseManager: PurchaseManaging) {
        self.purchaseManager = purchaseManager
    }

    func purchaseTip() async {
        state = .purchasing
        do {
            guard let product = try await purchaseManager.product(for: productIdentifier) else {
                state = .failed
                return
            }
            state = try await purchaseManager.purchase(product) ? .purchased : .failed
        } catch {
            state = .failed
        }
    }

    /// Checks entitlement rather than assuming purchase success implies an
    /// active subscription - the same distinction StoreKit itself draws:
    /// a completed purchase can later lapse (cancellation, billing failure)
    /// without this store observing that renewal event directly.
    func refreshSupporterStatus() async {
        supporterState = await purchaseManager.isEntitled(to: supporterProductIdentifier) ? .active : .idle
    }

    func purchaseSupporterSubscription() async {
        supporterState = .purchasing
        do {
            guard let product = try await purchaseManager.product(for: supporterProductIdentifier) else {
                supporterState = .failed
                return
            }
            supporterState = try await purchaseManager.purchase(product) ? .active : .failed
        } catch {
            supporterState = .failed
        }
    }
}
