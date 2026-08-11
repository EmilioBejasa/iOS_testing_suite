import Photos

/// Deterministic stand-in for `SystemPhotoLibraryAuthorizer` — safe to exercise in
/// any test, since it never touches the real Photos framework or shows a system
/// prompt.
public final class MockPhotoLibraryAuthorizer: PhotoLibraryAuthorizing {
    public var status: PHAuthorizationStatus

    public init(status: PHAuthorizationStatus = .notDetermined) {
        self.status = status
    }

    public func currentAuthorizationStatus() -> PHAuthorizationStatus {
        status
    }

    public func requestAuthorization() async -> PHAuthorizationStatus {
        status
    }
}
