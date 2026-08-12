import UIKit

/// Wraps `UIApplication.shared.isIdleTimerDisabled` (get and set), bridged
/// through `await MainActor.run { ... }` - the exact same technique
/// `SystemReviewRequester` already established for `UIApplication.shared`
/// in this repo.
public final class SystemIdleTimerControl: IdleTimerControlling {
    public init() {}

    public func setIdleTimerDisabled(_ disabled: Bool) async {
        await MainActor.run { UIApplication.shared.isIdleTimerDisabled = disabled }
    }

    public func isIdleTimerDisabled() async -> Bool {
        await MainActor.run { UIApplication.shared.isIdleTimerDisabled }
    }
}
