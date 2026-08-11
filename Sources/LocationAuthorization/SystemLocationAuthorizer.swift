import CoreLocation

/// Wraps `CLLocationManager`. Unlike `UNUserNotificationCenter`,
/// `CLLocationManager` has no native async authorization API — its
/// authorization callback is delegate-based (`locationManagerDidChangeAuthorization`),
/// bridged to `async` here via `CheckedContinuation`.
@available(iOS 14.0, *)
public final class SystemLocationAuthorizer: NSObject, LocationAuthorizing {
    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    public override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
    }

    public func currentAuthorizationStatus() -> CLAuthorizationStatus {
        manager.authorizationStatus
    }

    public func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
        // If status is already determined, requesting again shows no prompt and
        // locationManagerDidChangeAuthorization won't fire (status isn't
        // changing) - awaiting the continuation in that case would hang forever.
        let existingStatus = manager.authorizationStatus
        guard existingStatus == .notDetermined else { return existingStatus }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }
}

@available(iOS 14.0, *)
extension SystemLocationAuthorizer: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        continuation?.resume(returning: manager.authorizationStatus)
        continuation = nil
    }
}
