import Foundation

public enum AuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
}

/// Abstracts a permission-gated system service (local notifications here) so app
/// code never talks to `UNUserNotificationCenter` — or triggers its real system
/// permission dialog — directly. The same protocol+real+fake shape generalizes to
/// other system permissions (location, camera, photos): request authorization
/// through an injectable dependency, swap in a fake for tests so the real system
/// prompt never appears in headless CI.
public protocol ReminderScheduling {
    func requestAuthorization() async -> AuthorizationStatus
    func scheduleDailyReminder(hour: Int, minute: Int) async throws
    func cancelDailyReminder()
}
