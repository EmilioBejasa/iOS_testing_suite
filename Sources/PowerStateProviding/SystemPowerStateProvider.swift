import Foundation

/// Wraps `ProcessInfo.processInfo.isLowPowerModeEnabled`/`.thermalState` -
/// plain, synchronous Foundation reads, not UIKit, so no `@MainActor`
/// bridging is needed the way `IdleTimerControlling`'s `UIApplication.shared`
/// touchpoint requires. Thermal state changes are observed via
/// `ProcessInfo.thermalStateDidChangeNotification` on `NotificationCenter`
/// rather than polling.
public final class SystemPowerStateProvider: PowerStateProviding {
    private var observer: NSObjectProtocol?

    public init() {}

    public var isLowPowerModeEnabled: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    public var thermalState: ProcessInfo.ThermalState {
        ProcessInfo.processInfo.thermalState
    }

    public func startMonitoringThermalState(onChange: @escaping (ProcessInfo.ThermalState) -> Void) {
        stopMonitoringThermalState()
        observer = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            onChange(self.thermalState)
        }
    }

    public func stopMonitoringThermalState() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
    }

    deinit {
        stopMonitoringThermalState()
    }
}
