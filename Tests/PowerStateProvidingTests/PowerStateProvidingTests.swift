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

    /// Regression coverage for a real leak: a naive startMonitoringThermalState
    /// that just reassigns `observer` would leave the first NotificationCenter
    /// registration (and its onChange closure) live forever if start is called
    /// twice without an intervening stop - a caller re-entering a screen that
    /// starts monitoring in viewWillAppear, for example. Only reachable
    /// end-to-end by a real thermal-state change, which nothing in CI can
    /// force, so this only proves the double-start path itself doesn't crash;
    /// the fix (stopMonitoringThermalState() at the top of start) is what
    /// actually closes the leak.
    func testSystemProviderStartMonitoringThermalStateTwiceThenStopWithoutCrashing() {
        let provider = SystemPowerStateProvider()

        provider.startMonitoringThermalState { _ in }
        provider.startMonitoringThermalState { _ in }
        provider.stopMonitoringThermalState()
    }
}
