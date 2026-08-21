#if os(iOS)
import UIKit

/// Wraps `UIApplication.shared.isProtectedDataAvailable` directly - no
/// `MainActor` bridging needed, since Apple's headers mark this specific
/// property `nonisolated`. Monitors both
/// `protectedDataDidBecomeAvailableNotification` (fires `true`) and
/// `protectedDataWillBecomeUnavailableNotification` (fires `false`) via
/// `NotificationCenter`.
public final class SystemProtectedDataAvailabilityProvider: ProtectedDataAvailabilityProviding {
    private var availableObserver: NSObjectProtocol?
    private var unavailableObserver: NSObjectProtocol?

    public init() {}

    public var isProtectedDataAvailable: Bool {
        UIApplication.shared.isProtectedDataAvailable
    }

    public func startMonitoringProtectedDataAvailability(onChange: @escaping (Bool) -> Void) {
        stopMonitoringProtectedDataAvailability()
        availableObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil,
            queue: .main
        ) { _ in onChange(true) }
        unavailableObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil,
            queue: .main
        ) { _ in onChange(false) }
    }

    public func stopMonitoringProtectedDataAvailability() {
        if let availableObserver {
            NotificationCenter.default.removeObserver(availableObserver)
        }
        if let unavailableObserver {
            NotificationCenter.default.removeObserver(unavailableObserver)
        }
        availableObserver = nil
        unavailableObserver = nil
    }

    deinit {
        stopMonitoringProtectedDataAvailability()
    }
}
#endif
