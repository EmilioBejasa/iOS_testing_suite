#if os(iOS)
import AppTrackingTransparency

/// Wraps `ATTrackingManager`. `requestTrackingAuthorization(completionHandler:)`
/// is already a plain completion handler (not a delegate), so it bridges to
/// `async` directly via `CheckedContinuation` - same shape as
/// `SystemContactsAuthorizer`.
@available(iOS 14.0, *)
public final class SystemTrackingAuthorizer: TrackingAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> ATTrackingManager.AuthorizationStatus {
        ATTrackingManager.trackingAuthorizationStatus
    }

    public func requestAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
#endif
