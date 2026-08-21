#if os(iOS)
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
    /// does for UIApplication.shared. Deliberately doesn't assert the
    /// enabled flag reads back true after being set, unlike
    /// IdleTimerControllingTests' equivalent round-trip: the Simulator has
    /// no real battery, and isBatteryMonitoringEnabled doesn't reliably
    /// stick there (found via a failed CI run, not assumed in advance) -
    /// same "documented risk, untested real behavior" treatment
    /// HealthAuthorizationTests/SiriAuthorizationTests give calls a failed
    /// CI run already flagged as unsafe to assert on.
    func testSystemProviderCallsRealAPIWithoutCrashing() async {
        let provider = SystemBatteryStateProvider()

        await provider.setBatteryMonitoringEnabled(true)
        _ = await provider.isBatteryMonitoringEnabled()
        _ = await provider.batteryLevel()
        _ = await provider.batteryState()

        await provider.setBatteryMonitoringEnabled(false)
    }
}
#endif
