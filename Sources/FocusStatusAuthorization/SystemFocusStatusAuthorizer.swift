#if os(iOS)
import Intents

/// Wraps `INFocusStatusCenter`. `requestAuthorization(_:)` is a plain
/// completion handler, bridged to `async` via `CheckedContinuation` - same
/// shape as `SystemSiriAuthorizer`. `INFocusStatusCenter` is in the same
/// Intents-framework family as `INPreferences` (Siri) and requires the
/// "Communication Notifications" capability just to use the class, matching
/// the entitlement-crash risk `SiriAuthorizationTests` already discovered -
/// see `FocusStatusAuthorizationTests` for how the real authorizer is
/// treated as a result.
@available(iOS 15.0, *)
public final class SystemFocusStatusAuthorizer: FocusStatusAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> INFocusStatusAuthorizationStatus {
        INFocusStatusCenter.default.authorizationStatus
    }

    public func requestAuthorization() async -> INFocusStatusAuthorizationStatus {
        await withCheckedContinuation { continuation in
            INFocusStatusCenter.default.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
#endif
