import MediaPlayer

/// Deterministic stand-in for `SystemMediaLibraryAuthorizer` - safe to
/// exercise in any test, since it never touches the real media library or
/// shows a system prompt.
public final class MockMediaLibraryAuthorizer: MediaLibraryAuthorizing {
    public var status: MPMediaLibraryAuthorizationStatus
    public var authorizationResult: MPMediaLibraryAuthorizationStatus

    public init(
        status: MPMediaLibraryAuthorizationStatus = .notDetermined,
        authorizationResult: MPMediaLibraryAuthorizationStatus = .authorized
    ) {
        self.status = status
        self.authorizationResult = authorizationResult
    }

    public func currentAuthorizationStatus() -> MPMediaLibraryAuthorizationStatus {
        status
    }

    public func requestAuthorization() async -> MPMediaLibraryAuthorizationStatus {
        authorizationResult
    }
}
