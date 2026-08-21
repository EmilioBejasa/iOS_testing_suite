#if os(iOS)
import UIKit

/// Wraps `UIDevice.current`'s `isBatteryMonitoringEnabled`/`batteryLevel`/
/// `batteryState`, bridged through `await MainActor.run { ... }` - the exact
/// same technique `SystemIdleTimerControl`/`SystemAccessibilityStateProvider`
/// already established for UIKit reads in this repo.
public final class SystemBatteryStateProvider: BatteryStateProviding {
    public init() {}

    public func setBatteryMonitoringEnabled(_ enabled: Bool) async {
        await MainActor.run { UIDevice.current.isBatteryMonitoringEnabled = enabled }
    }

    public func isBatteryMonitoringEnabled() async -> Bool {
        await MainActor.run { UIDevice.current.isBatteryMonitoringEnabled }
    }

    public func batteryLevel() async -> Float {
        await MainActor.run { UIDevice.current.batteryLevel }
    }

    public func batteryState() async -> UIDevice.BatteryState {
        await MainActor.run { UIDevice.current.batteryState }
    }
}
#endif
