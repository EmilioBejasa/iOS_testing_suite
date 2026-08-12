import Speech

/// A seventh permission-gated system service, same protocol+real+fake shape as
/// `CameraAuthorization`/`MicrophoneAuthorization`. Uses
/// `SFSpeechRecognizerAuthorizationStatus` directly, same reasoning every other
/// module here gives for keeping a framework's own status type - it has no
/// `.limited`/`.restricted`-style nuance the others carry, but reinventing an
/// enum here would still make this module the odd one out.
public protocol SpeechRecognitionAuthorizing {
    func currentAuthorizationStatus() -> SFSpeechRecognizerAuthorizationStatus
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus
}
