import Speech

/// Wraps `SFSpeechRecognizer`. `requestAuthorization(_:)` is already a plain
/// completion handler (not a delegate), so it bridges to `async` directly via
/// `CheckedContinuation` - same shape as `SystemContactsAuthorizer`.
public final class SystemSpeechRecognitionAuthorizer: SpeechRecognitionAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }

    public func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
