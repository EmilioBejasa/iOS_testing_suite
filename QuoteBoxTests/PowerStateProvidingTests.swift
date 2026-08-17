import XCTest
import Foundation
import PowerStateProviding

final class PowerStateProvidingTests: XCTestCase {
    func testMockReturnsConfiguredState() {
        let provider = MockPowerStateProvider(isLowPowerModeEnabled: true)

        XCTAssertTrue(provider.isLowPowerModeEnabled)
    }

    func testMockDefaultsToFalse() {
        let provider = MockPowerStateProvider()

        XCTAssertFalse(provider.isLowPowerModeEnabled)
    }

    func testMockDefaultsToNominalThermalState() {
        let provider = MockPowerStateProvider()

        XCTAssertEqual(provider.thermalState, .nominal)
    }

    func testMockStartMonitoringThermalStateFiresImmediatelyWithCurrentState() {
        let provider = MockPowerStateProvider(thermalState: .fair)
        var received: [ProcessInfo.ThermalState] = []

        provider.startMonitoringThermalState { received.append($0) }

        XCTAssertEqual(received, [.fair])
    }

    func testMockSimulateThermalStateChangeDrivesOnChange() {
        let provider = MockPowerStateProvider()
        var received: [ProcessInfo.ThermalState] = []
        provider.startMonitoringThermalState { received.append($0) }

        provider.simulateThermalStateChange(to: .serious)

        XCTAssertEqual(received, [.nominal, .serious])
        XCTAssertEqual(provider.thermalState, .serious)
    }

    func testMockStopMonitoringThermalStateStopsFurtherUpdates() {
        let provider = MockPowerStateProvider()
        var received: [ProcessInfo.ThermalState] = []
        provider.startMonitoringThermalState { received.append($0) }
        provider.stopMonitoringThermalState()

        provider.simulateThermalStateChange(to: .critical)

        XCTAssertEqual(received, [.nominal])
    }

    /// Safe to exercise for real - ProcessInfo.isLowPowerModeEnabled/.thermalState
    /// are plain, synchronous, non-prompting reads, no UIKit/MainActor concern.
    func testSystemProviderReadsWithoutCrashing() {
        let provider = SystemPowerStateProvider()

        _ = provider.isLowPowerModeEnabled
        _ = provider.thermalState
    }

    /// Constructing and tearing down the real notification observer is safe
    /// even though nothing in CI can force an actual thermal state change to
    /// fire it - same "constructed but not exercised for firing" treatment
    /// NetworkReachabilityMonitoringTests gives SystemNetworkReachabilityMonitor.
    func testSystemProviderStartAndStopMonitoringThermalStateWithoutCrashing() {
        let provider = SystemPowerStateProvider()

        provider.startMonitoringThermalState { _ in }
        provider.stopMonitoringThermalState()
    }
}
