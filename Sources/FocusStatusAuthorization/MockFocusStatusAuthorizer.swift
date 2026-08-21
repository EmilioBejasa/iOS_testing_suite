#if canImport(Intents)
import Intents

/// Deterministic stand-in for `SystemFocusStatusAuthorizer` - safe to
/// exercise in any test, since it never touches the real focus status
/// center or shows a system prompt.
@available(iOS 15.0, *)
public final class MockFocusStatusAuthorizer: FocusStatusAuthorizing {
    public var status: INFocusStatusAuthorizationStatus
    public var authorizationResult: INFocusStatusAuthorizationStatus

    public init(
        status: INFocusStatusAuthorizationStatus = .notDetermined,
        authorizationResult: INFocusStatusAuthorizationStatus = .authorized
    ) {
        self.status = status
        self.authorizationResult = authorizationResult
    }

    public func currentAuthorizationStatus() -> INFocusStatusAuthorizationStatus {
        status
    }

    public func requestAuthorization() async -> INFocusStatusAuthorizationStatus {
        authorizationResult
    }
}
#endif
