import AVFoundation

/// Deterministic stand-in for `SystemCameraAuthorizer` - safe to exercise in any
/// test, since it never touches the real camera or shows a system prompt.
public final class MockCameraAuthorizer: CameraAuthorizing {
    public var status: AVAuthorizationStatus
    public var accessResult: Bool

    public init(status: AVAuthorizationStatus = .notDetermined, accessResult: Bool = true) {
        self.status = status
        self.accessResult = accessResult
    }

    public func currentAuthorizationStatus() -> AVAuthorizationStatus {
        status
    }

    public func requestAccess() async -> Bool {
        accessResult
    }
}
