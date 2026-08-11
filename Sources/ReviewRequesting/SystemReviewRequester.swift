import StoreKit
import UIKit

/// Wraps `AppStore.requestReview(in:)`, finding the foreground-active
/// `UIWindowScene` to present in. Side-effect-safe to call at any time - the
/// system itself decides whether to show anything and rate-limits it, so unlike
/// `PushRegistering`/`AppleSignIn`'s prompting halves, this is exercised for
/// real in `ReviewRequestingTests.swift`.
@available(iOS 16.0, *)
public final class SystemReviewRequester: ReviewRequesting {
    public init() {}

    public func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else {
            return
        }
        AppStore.requestReview(in: scene)
    }
}
