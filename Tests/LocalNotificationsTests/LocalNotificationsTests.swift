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

    // No SystemReminderScheduler test here, even for a nominally safe call like
    // cancelDailyReminder(): SystemReminderScheduler's default `center` argument
    // eagerly evaluates `UNUserNotificationCenter.current()`, which crashes with
    // "bundleProxyForCurrentProcess is nil" outside a real host app bundle -
    // confirmed by CI on both `swift test` and `xcodebuild test -scheme
    // iOSTestKit-Package`. Unlike RemindersAuthorizationTests/CalendarAuthorizationTests,
    // there's no way to construct SystemReminderScheduler at all in this
    // environment, so it needs the same "real host app bundle required"
    // treatment CONTRIBUTING.md documents for PurchaseSupport/Clipboard/IdleTimer.
}
