import AVFoundation

/// Wraps `AVCaptureDevice`, same bridging shape as `SystemCameraAuthorizer` -
/// `requestAccess(for:completionHandler:)` is a plain completion handler,
/// bridged to `async` via `CheckedContinuation`.
public final class SystemMicrophoneAuthorizer: MicrophoneAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    public func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
