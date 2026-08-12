import Speech

/// Deterministic stand-in for `SystemSpeechRecognitionAuthorizer` - safe to
/// exercise in any test, since it never touches the real speech recognizer or
/// shows a system prompt.
public final class MockSpeechRecognitionAuthorizer: SpeechRecognitionAuthorizing {
    public var status: SFSpeechRecognizerAuthorizationStatus
    public var authorizationResult: SFSpeechRecognizerAuthorizationStatus

    public init(
        status: SFSpeechRecognizerAuthorizationStatus = .notDetermined,
        authorizationResult: SFSpeechRecognizerAuthorizationStatus = .authorized
    ) {
        self.status = status
        self.authorizationResult = authorizationResult
    }

    public func currentAuthorizationStatus() -> SFSpeechRecognizerAuthorizationStatus {
        status
    }

    public func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        authorizationResult
    }
}
