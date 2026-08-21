#if os(iOS)
import Intents

/// Deterministic stand-in for `SystemSiriAuthorizer` - safe to exercise in
/// any test, since it never touches the real Siri preferences or shows a
/// system prompt.
public final class MockSiriAuthorizer: SiriAuthorizing {
    public var status: INSiriAuthorizationStatus
    public var authorizationResult: INSiriAuthorizationStatus

    public init(
        status: INSiriAuthorizationStatus = .notDetermined,
        authorizationResult: INSiriAuthorizationStatus = .authorized
    ) {
        self.status = status
        self.authorizationResult = authorizationResult
    }

    public func currentAuthorizationStatus() -> INSiriAuthorizationStatus {
        status
    }

    public func requestAuthorization() async -> INSiriAuthorizationStatus {
        authorizationResult
    }
}
#endif
