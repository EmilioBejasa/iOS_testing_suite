import Foundation

public enum PushRegistrationOutcome: Equatable {
    case token(Data)
    case failed(String)
}

/// Distinct from `LocalNotifications`'s `ReminderScheduling`, which covers the
/// alert/badge/sound authorization prompt shared by local and remote
/// notifications. This covers the second, separate step: registering the device
/// with APNs. Unlike a permission request, this never shows a system dialog.
public protocol PushRegistering {
    func registerForRemoteNotifications() async -> PushRegistrationOutcome
}
