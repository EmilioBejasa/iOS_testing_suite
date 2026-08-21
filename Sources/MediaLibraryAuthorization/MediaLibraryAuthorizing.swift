#if os(iOS)
import MediaPlayer

/// A fourteenth permission-gated system service, same protocol+real+fake
/// shape as the others. Uses `MPMediaLibraryAuthorizationStatus` directly,
/// same reasoning every other module here gives for keeping a framework's
/// own status type.
public protocol MediaLibraryAuthorizing {
    func currentAuthorizationStatus() -> MPMediaLibraryAuthorizationStatus
    func requestAuthorization() async -> MPMediaLibraryAuthorizationStatus
}
#endif
