import CoreMotion

/// Deterministic stand-in for `SystemMotionAuthorizer` - safe to exercise in
/// any test, since it never touches the real motion activity manager.
public final class MockMotionAuthorizer: MotionAuthorizing {
    public var status: CMAuthorizationStatus

    public init(status: CMAuthorizationStatus = .notDetermined) {
        self.status = status
    }

    public func currentAuthorizationStatus() -> CMAuthorizationStatus {
        status
    }
}
