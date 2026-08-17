import Foundation

/// Lets app code ask "is Low Power Mode on?" through an injectable dependency
/// instead of calling `ProcessInfo.processInfo.isLowPowerModeEnabled`
/// directly, so a test can force either side of a power-aware code path
/// (reduced polling, disabled animations) deterministically.
///
/// Also covers thermal state, the same `ProcessInfo` framework's other
/// power-adjacent read - kept in this module rather than split into a
/// second one, the same "don't fragment one framework across modules"
/// reasoning `PurchaseSupport`'s subscription support was added under.
/// `thermalState`/`startMonitoringThermalState`/`stopMonitoringThermalState`
/// follow `NetworkReachabilityMonitoring`'s `current<X> { get }` +
/// `startMonitoring`/`stopMonitoring` shape.
public protocol PowerStateProviding {
    var isLowPowerModeEnabled: Bool { get }

    var thermalState: ProcessInfo.ThermalState { get }
    func startMonitoringThermalState(onChange: @escaping (ProcessInfo.ThermalState) -> Void)
    func stopMonitoringThermalState()
}
