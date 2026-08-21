#if canImport(MediaPlayer)
import MediaPlayer

/// Wraps `MPMediaLibrary`. `requestAuthorization(_:)` is already a plain
/// completion handler (not a delegate), so it bridges to `async` directly via
/// `CheckedContinuation` - same shape as `SystemContactsAuthorizer`.
public final class SystemMediaLibraryAuthorizer: MediaLibraryAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> MPMediaLibraryAuthorizationStatus {
        MPMediaLibrary.authorizationStatus()
    }

    public func requestAuthorization() async -> MPMediaLibraryAuthorizationStatus {
        await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
#endif
