#if os(iOS)
import Intents

/// Wraps `INPreferences`. `requestSiriAuthorization(_:)` is already a plain
/// completion handler (not a delegate), so it bridges to `async` directly via
/// `CheckedContinuation` - same shape as `SystemSpeechRecognitionAuthorizer`.
public final class SystemSiriAuthorizer: SiriAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> INSiriAuthorizationStatus {
        INPreferences.siriAuthorizationStatus()
    }

    public func requestAuthorization() async -> INSiriAuthorizationStatus {
        await withCheckedContinuation { continuation in
            INPreferences.requestSiriAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
#endif
