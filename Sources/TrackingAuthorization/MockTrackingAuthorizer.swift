import AppTrackingTransparency

/// Deterministic stand-in for `SystemTrackingAuthorizer` - safe to exercise in
/// any test, since it never touches the real tracking manager or shows a
/// system prompt.
public final class MockTrackingAuthorizer: TrackingAuthorizing {
    public var status: ATTrackingManager.AuthorizationStatus
    public var authorizationResult: ATTrackingManager.AuthorizationStatus

    public init(
        status: ATTrackingManager.AuthorizationStatus = .notDetermined,
        authorizationResult: ATTrackingManager.AuthorizationStatus = .authorized
    ) {
        self.status = status
        self.authorizationResult = authorizationResult
    }

    public func currentAuthorizationStatus() -> ATTrackingManager.AuthorizationStatus {
        status
    }

    public func requestAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        authorizationResult
    }
}
