import AVFoundation

/// Wraps `AVCaptureDevice`. `requestAccess(for:completionHandler:)` is already a
/// plain completion handler (not a delegate), so it bridges to `async` directly
/// via `CheckedContinuation` - same shape as `SystemContactsAuthorizer`.
public final class SystemCameraAuthorizer: CameraAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    public func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
