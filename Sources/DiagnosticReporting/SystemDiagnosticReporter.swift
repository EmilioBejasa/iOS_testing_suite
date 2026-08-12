import MetricKit

/// Wraps `MXMetricManager.shared`. `MXMetricManagerSubscriber` requires
/// `NSObjectProtocol` conformance, so this is an `NSObject` subclass unlike
/// most other `System*` types in this kit. `didReceive` payloads are
/// deliberately no-ops: `MXMetricPayload`/`MXDiagnosticPayload` have no
/// public initializer, the same "can't fabricate Apple's own type" story
/// `BackgroundTaskScheduling`/`PurchaseSupport`/`AppleSignIn` already give,
/// so there's nothing this kit can construct to feed a caller-supplied
/// handler with anyway.
///
/// `MXDiagnosticPayload` is `@available(iOS 14.0, *)` - one version newer
/// than `MXMetricPayload`/`MXMetricManager` itself (iOS 13) - so the whole
/// class needs to be pinned to the higher watermark, same class of fix
/// `BluetoothAuthorization` needed for `CBManagerAuthorization`.
@available(iOS 14.0, *)
public final class SystemDiagnosticReporter: NSObject, DiagnosticReporting, MXMetricManagerSubscriber {
    public override init() {
        super.init()
    }

    public func startReporting() {
        MXMetricManager.shared.add(self)
    }

    public func stopReporting() {
        MXMetricManager.shared.remove(self)
    }

    public func didReceive(_ payloads: [MXMetricPayload]) {}

    public func didReceive(_ payloads: [MXDiagnosticPayload]) {}
}
