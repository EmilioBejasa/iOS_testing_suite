import AVFoundation

/// A fifth permission-gated system service, same protocol+real+fake shape as
/// `ContactsAuthorization`/`LocationAuthorization`/`PhotoLibraryAuthorization`.
/// Uses `AVAuthorizationStatus` directly, same reasoning every other module
/// here gives for keeping a framework's own status type.
public protocol CameraAuthorizing {
    func currentAuthorizationStatus() -> AVAuthorizationStatus
    func requestAccess() async -> Bool
}
