import UIKit

/// Lets app code ask "is file-protected/Keychain data actually accessible
/// right now?" through an injectable dependency instead of reading
/// `UIApplication.shared.isProtectedDataAvailable` directly, so a test can
/// force either side of a protection-aware code path (defer a Keychain read
/// until after first unlock, e.g. in a background-launch or
/// early-in-`didFinishLaunching` scenario) deterministically. `false` here
/// means the device is locked and files with `.complete`/`.completeUnlessOpen`
/// data protection can't be read or written yet - the user must unlock first.
///
/// Unlike every other `UIApplication.shared` touchpoint in this kit
/// (`SystemReviewRequester`, `SystemIdleTimerControl`), Apple's own headers
/// mark `isProtectedDataAvailable` `nonisolated` on an otherwise
/// `@MainActor` class - a deliberate exemption, since this property has to
/// be safely readable from any context, including very early in app launch
/// before the main run loop is spinning. So this protocol's read is a plain
/// synchronous function, not `async`, the one UIKit module in this kit
/// that isn't. Monitors
/// `UIApplication.protectedDataDidBecomeAvailableNotification`/
/// `protectedDataWillBecomeUnavailableNotification` via `NotificationCenter`,
/// the same `PowerStateProviding` thermal-state shape - a read plus
/// `startMonitoring`/`stopMonitoring`.
public protocol ProtectedDataAvailabilityProviding {
    var isProtectedDataAvailable: Bool { get }
    func startMonitoringProtectedDataAvailability(onChange: @escaping (Bool) -> Void)
    func stopMonitoringProtectedDataAvailability()
}
