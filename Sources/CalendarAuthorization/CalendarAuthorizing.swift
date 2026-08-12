import EventKit

/// An eighth permission-gated system service, same protocol+real+fake shape as
/// `ContactsAuthorization`/`CameraAuthorization`. Uses `EKAuthorizationStatus`
/// directly, same reasoning every other module here gives for keeping a
/// framework's own status type - iOS 17 added `.fullAccess`/`.writeOnly` cases
/// this module would lose by reinventing a simplified enum.
public protocol CalendarAuthorizing {
    func currentAuthorizationStatus() -> EKAuthorizationStatus
    func requestAccess() async -> Bool
}
