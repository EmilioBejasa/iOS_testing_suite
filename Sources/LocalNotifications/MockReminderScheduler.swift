/// Deterministic stand-in for `SystemReminderScheduler`, wired in by launch
/// arguments so XCUITests never trigger the real system permission dialog — a
/// dialog XCTest can't dismiss headlessly, which would hang CI.
public final class MockReminderScheduler: ReminderScheduling {
    public var authorizationResult: AuthorizationStatus
    public private(set) var scheduledReminder: (hour: Int, minute: Int)?
    public private(set) var didCancel = false

    public init(authorizationResult: AuthorizationStatus) {
        self.authorizationResult = authorizationResult
    }

    public func requestAuthorization() async -> AuthorizationStatus {
        authorizationResult
    }

    public func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        scheduledReminder = (hour, minute)
    }

    public func cancelDailyReminder() {
        scheduledReminder = nil
        didCancel = true
    }
}
