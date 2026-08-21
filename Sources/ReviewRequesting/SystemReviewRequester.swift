#if os(iOS)
import StoreKit
import UIKit

/// Wraps `AppStore.requestReview(in:)`, finding the foreground-active
/// `UIWindowScene` to present in. Side-effect-safe to call at any time - the
/// system itself decides whether to show anything and rate-limits it, so unlike
/// `PushRegistering`/`AppleSignIn`'s prompting halves, this is exercised for
/// real in `ReviewRequestingTests.swift`. `AppStore.requestReview(in:)` and
/// `UIApplication.shared` are both main-actor-isolated, but `requestReview()`
/// itself stays a plain nonisolated method to satisfy the protocol without
/// forcing every caller onto the main actor - the isolated work is deferred
/// into a `Task`, same technique `QuoteStore` uses for its reachability
/// monitor's callback.
@available(iOS 16.0, *)
public final class SystemReviewRequester: ReviewRequesting {
    public init() {}

    public func requestReview() {
        Task { @MainActor in
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            else {
                return
            }
            AppStore.requestReview(in: scene)
        }
    }
}
#endif
