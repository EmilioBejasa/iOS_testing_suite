import EventKit

/// Wraps `EKEventStore`, same shape as `SystemCalendarAuthorizer`:
/// `requestFullAccessToReminders()` (iOS 17+) is already a native
/// `async throws` API, no completion-handler bridging needed. Confirmed via
/// WebSearch before writing this: same iOS 17+ shape as
/// `requestFullAccessToEvents()`, no entitlement quirk beyond the usual
/// usage-description key.
@available(iOS 17.0, macOS 14.0, *)
public final class SystemRemindersAuthorizer: RemindersAuthorizing {
    private let store = EKEventStore()

    public init() {}

    public func currentAuthorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .reminder)
    }

    public func requestAccess() async -> Bool {
        (try? await store.requestFullAccessToReminders()) ?? false
    }
}
