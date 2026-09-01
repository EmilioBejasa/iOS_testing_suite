import AnalyticsLogging
import BundleInfoProviding
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
    private let analyticsLogger: AnalyticsLogging
    private let bundleInfo: BundleInfoProviding
    private let productIdentifier = "com.quotebox.tip"
    private let supporterProductIdentifier = "com.quotebox.supporter.monthly"

    init(
        purchaseManager: PurchaseManaging,
        analyticsLogger: AnalyticsLogging = SystemAnalyticsLogger(),
        bundleInfo: BundleInfoProviding = SystemBundleInfoProvider()
    ) {
        self.purchaseManager = purchaseManager
        self.analyticsLogger = analyticsLogger
        self.bundleInfo = bundleInfo
    }

    private func logAnalyticsEvent(_ event: String, parameters: [String: String] = [:]) {
        var parameters = parameters
        parameters["appVersion"] = bundleInfo.appVersion
        analyticsLogger.log(event: event, parameters: parameters)
    }

    /// `state == .purchased` is unreachable from `TipJarStoreTests`'
    /// bare-`MockPurchaseManager` cases: `product(for:)` defaults to `nil`
    /// and `Product` has no public initializer to fabricate a non-nil one
    /// (see `TipJarStoreTests`'s own doc comment). Deterministic coverage of
    /// `"tip_purchased"` logging instead lives in
    /// `TipJarStoreRealSessionTests`, which fetches a real `Product` via
    /// `SKTestSession` first, the same approach
    /// `PurchaseSupportRealSessionTests` uses at the kit level.
    func purchaseTip() async {
        state = .purchasing
        do {
            guard let product = try await purchaseManager.product(for: productIdentifier) else {
                state = .failed
                return
            }
            let purchased = try await purchaseManager.purchase(product)
            state = purchased ? .purchased : .failed
            if purchased {
                logAnalyticsEvent("tip_purchased", parameters: ["productID": productIdentifier])
            }
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
            let purchased = try await purchaseManager.purchase(product)
            supporterState = purchased ? .active : .failed
            if purchased {
                logAnalyticsEvent("supporter_subscribed", parameters: ["productID": supporterProductIdentifier])
            }
        } catch {
            supporterState = .failed
        }
    }
}
