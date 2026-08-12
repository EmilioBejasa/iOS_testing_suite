import AppTrackingTransparency

/// A ninth permission-gated system service, same protocol+real+fake shape as
/// the others. Uses `ATTrackingManager.AuthorizationStatus` directly, same
/// reasoning every other module here gives for keeping a framework's own
/// status type. Distinct from every other permission in this kit in *why* it
/// matters: it's the one gate here tied directly to App Store review
/// requirements (Apple rejects apps that track without first showing this
/// prompt), not just a nice-to-have capability check.
public protocol TrackingAuthorizing {
    func currentAuthorizationStatus() -> ATTrackingManager.AuthorizationStatus
    func requestAuthorization() async -> ATTrackingManager.AuthorizationStatus
}
