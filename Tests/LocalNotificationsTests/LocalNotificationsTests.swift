import XCTest
import LocalNotifications

final class LocalNotificationsTests: XCTestCase {
    func testMockRequestAuthorizationReturnsConfiguredResult() async {
        let scheduler = MockReminderScheduler(authorizationResult: .authorized)

        let result = await scheduler.requestAuthorization()

        XCTAssertEqual(result, .authorized)
    }

    func testMockRequestAuthorizationReturnsDeniedWhenConfiguredDenied() async {
        let scheduler = MockReminderScheduler(authorizationResult: .denied)

        let result = await scheduler.requestAuthorization()

        XCTAssertEqual(result, .denied)
    }

    func testMockScheduleDailyReminderRecordsHourAndMinute() async throws {
        let scheduler = MockReminderScheduler(authorizationResult: .authorized)

        try await scheduler.scheduleDailyReminder(hour: 9, minute: 30)

        XCTAssertEqual(scheduler.scheduledReminder?.hour, 9)
        XCTAssertEqual(scheduler.scheduledReminder?.minute, 30)
    }

    func testMockCancelDailyReminderClearsReminderAndRecordsCancellation() async throws {
        let scheduler = MockReminderScheduler(authorizationResult: .authorized)
        try await scheduler.scheduleDailyReminder(hour: 9, minute: 0)

        scheduler.cancelDailyReminder()

        XCTAssertNil(scheduler.scheduledReminder)
        XCTAssertTrue(scheduler.didCancel)
    }

    func testMockDefaultsHaveNoScheduledReminderAndNoCancellation() {
        let scheduler = MockReminderScheduler(authorizationResult: .notDetermined)

        XCTAssertNil(scheduler.scheduledReminder)
        XCTAssertFalse(scheduler.didCancel)
    }

    /// Safe to exercise for real: `cancelDailyReminder()` only calls
    /// `UNUserNotificationCenter.removePendingNotificationRequests`, which never
    /// prompts - unlike `requestAuthorization()`, which triggers the real system
    /// permission dialog per `SystemReminderScheduler`'s own doc comment and must
    /// never be called for real in a test. Removing a non-existent pending
    /// request is a documented no-op, so this has no lasting side effect worth
    /// avoiding.
    func testSystemSchedulerCancelDoesNotPrompt() {
        let scheduler = SystemReminderScheduler()

        scheduler.cancelDailyReminder()
    }
}
