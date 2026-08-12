import EventKit

/// Deterministic stand-in for `SystemCalendarAuthorizer` - safe to exercise in
/// any test, since it never touches the real event store or shows a system
/// prompt.
public final class MockCalendarAuthorizer: CalendarAuthorizing {
    public var status: EKAuthorizationStatus
    public var accessResult: Bool

    public init(status: EKAuthorizationStatus = .notDetermined, accessResult: Bool = true) {
        self.status = status
        self.accessResult = accessResult
    }

    public func currentAuthorizationStatus() -> EKAuthorizationStatus {
        status
    }

    public func requestAccess() async -> Bool {
        accessResult
    }
}
