import AppTrackingTransparency

/// A ninth permission-gated system service, same protocol+real+fake shape as
/// the others. Uses `ATTrackingManager.AuthorizationStatus` directly, same
/// reasoning every other module here gives for keeping a framework's own
/// status type. Distinct from every other permission in this kit in *why* it
/// matters: it's the one gate here tied directly to App Store review
/// requirements (Apple rejects apps that track without first showing this
/// prompt), not just a nice-to-have capability check.
///
/// `ATTrackingManager` itself is `@available(iOS 14, *)` in Apple's headers,
/// so merely naming `ATTrackingManager.AuthorizationStatus` here - even
/// without calling anything - requires this annotation too: the package
/// compiles against its own iOS 13 floor (`Package.swift`), independent of
/// whatever deployment target a consuming app like QuoteBox sets.
@available(iOS 14.0, *)
public protocol TrackingAuthorizing {
    func currentAuthorizationStatus() -> ATTrackingManager.AuthorizationStatus
    func requestAuthorization() async -> ATTrackingManager.AuthorizationStatus
}
