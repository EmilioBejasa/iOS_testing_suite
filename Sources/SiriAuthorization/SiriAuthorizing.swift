#if canImport(Intents)
import Intents

/// A thirteenth permission-gated system service, same protocol+real+fake
/// shape as `SpeechRecognitionAuthorization`. Uses `INSiriAuthorizationStatus`
/// directly, same reasoning every other module here gives for keeping a
/// framework's own status type.
public protocol SiriAuthorizing {
    func currentAuthorizationStatus() -> INSiriAuthorizationStatus
    func requestAuthorization() async -> INSiriAuthorizationStatus
}
#endif
