import CoreLocation

/// Generalizes `LocalNotifications`'s protocol+real+fake shape to a second system
/// permission. Uses `CLAuthorizationStatus` directly (CoreLocation's own richer
/// type — `notDetermined`/`restricted`/`denied`/`authorizedWhenInUse`/`authorizedAlways`)
/// rather than reinventing a simplified enum that would lose that distinction.
public protocol LocationAuthorizing {
    func currentAuthorizationStatus() -> CLAuthorizationStatus
    func requestWhenInUseAuthorization() async -> CLAuthorizationStatus
}
