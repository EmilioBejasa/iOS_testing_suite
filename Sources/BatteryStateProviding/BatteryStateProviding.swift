#if os(iOS)
import UIKit

/// Lets app code ask "how much charge is left, and is the device plugged
/// in?" through an injectable dependency instead of reading
/// `UIDevice.current` directly, so a test can force any battery
/// level/charging combination deterministically (skip a background sync
/// below 20% unplugged, badge a "charging" indicator). Distinct from
/// `PowerStateProviding`: that wraps `ProcessInfo` (Low Power Mode, thermal
/// state) - plain Foundation reads with no `@MainActor` concern; this wraps
/// `UIDevice`, UIKit surface, so methods are `async` from the start, the
/// same reasoning `IdleTimerControlling`/`AccessibilityStateProviding` give
/// for their own `UIApplication`/`UIAccessibility` touchpoints. Keeps
/// `UIDevice.BatteryState` directly (`.unknown`/`.unplugged`/`.charging`/
/// `.full`), same reasoning every status-checking module gives for keeping a
/// framework's own type. Reading `batteryLevel`/`batteryState` requires
/// monitoring to be enabled first - `UIDevice` returns `-1.0`/`.unknown`
/// otherwise - so this protocol exposes the enable/disable toggle rather
/// than assuming it's already on.
public protocol BatteryStateProviding {
    func setBatteryMonitoringEnabled(_ enabled: Bool) async
    func isBatteryMonitoringEnabled() async -> Bool
    func batteryLevel() async -> Float
    func batteryState() async -> UIDevice.BatteryState
}
#endif
