import Foundation

/// Wraps `ProcessInfo.processInfo.isLowPowerModeEnabled` - a plain,
/// synchronous Foundation read, not UIKit, so no `@MainActor` bridging is
/// needed the way `IdleTimerControlling`'s `UIApplication.shared` touchpoint
/// requires.
public final class SystemPowerStateProvider: PowerStateProviding {
    public init() {}

    public var isLowPowerModeEnabled: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
