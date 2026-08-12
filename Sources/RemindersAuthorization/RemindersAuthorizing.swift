import EventKit

/// Sibling to `CalendarAuthorization`, same `EventKit` framework, different
/// entity type (`.reminder`, not `.event`). Uses `EKAuthorizationStatus`
/// directly, same reasoning every other module here gives for keeping a
/// framework's own status type.
public protocol RemindersAuthorizing {
    func currentAuthorizationStatus() -> EKAuthorizationStatus
    func requestAccess() async -> Bool
}
