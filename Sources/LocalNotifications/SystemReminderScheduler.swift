import UserNotifications

/// Wraps `UNUserNotificationCenter` behind `ReminderScheduling`. Requesting
/// authorization through this triggers the real system permission dialog — never
/// call it from a UI test; use `MockReminderScheduler` there instead.
public final class SystemReminderScheduler: ReminderScheduling {
    private static let reminderIdentifier = "dailyReminder"

    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func requestAuthorization() async -> AuthorizationStatus {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    public func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "New quote waiting"
        content.body = "Come back for today's quote."

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: Self.reminderIdentifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    public func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
    }
}
