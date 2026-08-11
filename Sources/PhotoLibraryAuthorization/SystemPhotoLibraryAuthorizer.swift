import Photos

/// Wraps `PHPhotoLibrary`. Unlike `CLLocationManager`, `PHPhotoLibrary` already
/// exposes a native `async` authorization API (iOS 14+), so no delegate/
/// continuation bridging is needed here the way `SystemLocationAuthorizer`
/// requires for `CLLocationManager`'s callback-based one.
@available(iOS 14.0, *)
public final class SystemPhotoLibraryAuthorizer: PhotoLibraryAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    public func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
}
