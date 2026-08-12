import AVFoundation

/// Deterministic stand-in for `SystemMicrophoneAuthorizer` - safe to exercise
/// in any test, since it never touches the real microphone or shows a system
/// prompt.
public final class MockMicrophoneAuthorizer: MicrophoneAuthorizing {
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
