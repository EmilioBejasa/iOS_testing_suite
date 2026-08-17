import XCTest
import UIKit
import BatteryStateProviding

final class BatteryStateProvidingTests: XCTestCase {
    func testMockReturnsConfiguredState() async {
        let provider = MockBatteryStateProvider(monitoringEnabled: true, level: 0.42, state: .charging)

        let enabled = await provider.isBatteryMonitoringEnabled()
        let level = await provider.batteryLevel()
        let state = await provider.batteryState()

        XCTAssertTrue(enabled)
        XCTAssertEqual(level, 0.42)
        XCTAssertEqual(state, .charging)
    }

    func testMockDefaultsToMonitoringDisabled() async {
        let provider = MockBatteryStateProvider()

        let enabled = await provider.isBatteryMonitoringEnabled()
        let level = await provider.batteryLevel()
        let state = await provider.batteryState()

        XCTAssertFalse(enabled)
        XCTAssertEqual(level, -1.0)
        XCTAssertEqual(state, .unknown)
    }

    func testMockSetBatteryMonitoringEnabledRoundTrips() async {
        let provider = MockBatteryStateProvider()

        await provider.setBatteryMonitoringEnabled(true)
        let enabled = await provider.isBatteryMonitoringEnabled()

        XCTAssertTrue(enabled)
    }

    /// Safe to exercise for real - toggling isBatteryMonitoringEnabled and
    /// reading battery level/state never prompts or crashes, bridged
    /// through MainActor.run the same way SystemIdleTimerControl already
    /// does for UIApplication.shared.
    func testSystemProviderRoundTripsMonitoringAndReadsWithoutCrashing() async {
        let provider = SystemBatteryStateProvider()

        await provider.setBatteryMonitoringEnabled(true)
        let enabled = await provider.isBatteryMonitoringEnabled()
        XCTAssertTrue(enabled)

        _ = await provider.batteryLevel()
        _ = await provider.batteryState()

        await provider.setBatteryMonitoringEnabled(false)
    }
}
