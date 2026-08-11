import CoreLocation

/// Deterministic stand-in for `SystemLocationAuthorizer` — safe to exercise in
/// any test, since it never touches real CoreLocation or shows a system prompt.
public final class MockLocationAuthorizer: LocationAuthorizing {
    public var status: CLAuthorizationStatus

    public init(status: CLAuthorizationStatus = .notDetermined) {
        self.status = status
    }

    public func currentAuthorizationStatus() -> CLAuthorizationStatus {
        status
    }

    public func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
        status
    }
}
