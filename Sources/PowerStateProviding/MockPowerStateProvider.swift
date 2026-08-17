import Foundation

/// Deterministic stand-in for `SystemPowerStateProvider` - safe to exercise
/// in any test, since it never touches the real device power state.
public final class MockPowerStateProvider: PowerStateProviding {
    public var isLowPowerModeEnabled: Bool
    public private(set) var thermalState: ProcessInfo.ThermalState
    private var onThermalStateChange: ((ProcessInfo.ThermalState) -> Void)?

    public init(isLowPowerModeEnabled: Bool = false, thermalState: ProcessInfo.ThermalState = .nominal) {
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.thermalState = thermalState
    }

    public func startMonitoringThermalState(onChange: @escaping (ProcessInfo.ThermalState) -> Void) {
        onThermalStateChange = onChange
        onChange(thermalState)
    }

    public func stopMonitoringThermalState() {
        onThermalStateChange = nil
    }

    /// Drives `onChange` manually, simulating a thermal state change a test
    /// wants to react to - same shape as `MockNetworkReachabilityMonitor`'s
    /// `simulateStatusChange(to:)`.
    public func simulateThermalStateChange(to state: ProcessInfo.ThermalState) {
        thermalState = state
        onThermalStateChange?(state)
    }
}
