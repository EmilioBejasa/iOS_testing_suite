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

    private(set) var state: State = .idle

    private let purchaseManager: PurchaseManaging
    private let productIdentifier = "com.quotebox.tip"

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
}
