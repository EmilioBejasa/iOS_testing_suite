#if os(iOS)
import UIKit

/// Deterministic stand-in for `SystemBatteryStateProvider` - safe to
/// exercise in any test, since it never touches the real device battery.
public final class MockBatteryStateProvider: BatteryStateProviding {
    public private(set) var monitoringEnabled: Bool
    public var level: Float
    public var state: UIDevice.BatteryState

    public init(monitoringEnabled: Bool = false, level: Float = -1.0, state: UIDevice.BatteryState = .unknown) {
        self.monitoringEnabled = monitoringEnabled
        self.level = level
        self.state = state
    }

    public func setBatteryMonitoringEnabled(_ enabled: Bool) async {
        monitoringEnabled = enabled
    }

    public func isBatteryMonitoringEnabled() async -> Bool {
        monitoringEnabled
    }

    public func batteryLevel() async -> Float {
        level
    }

    public func batteryState() async -> UIDevice.BatteryState {
        state
    }
}
#endif
