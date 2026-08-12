import AVFoundation

/// A sixth permission-gated system service, same protocol+real+fake shape as
/// `CameraAuthorization`. Deliberately checks the `.audio` media type through
/// `AVCaptureDevice` rather than `AVAudioApplication`'s `recordPermission` (the
/// other native option, iOS 17+) - that would raise this module's floor above
/// the package's iOS 13 minimum for a distinction (audio-session recording vs.
/// capture-device audio) no app in this kit needs, and it would give
/// `CameraAuthorization`/`MicrophoneAuthorization` two different status enum
/// families instead of sharing `AVAuthorizationStatus`.
public protocol MicrophoneAuthorizing {
    func currentAuthorizationStatus() -> AVAuthorizationStatus
    func requestAccess() async -> Bool
}
