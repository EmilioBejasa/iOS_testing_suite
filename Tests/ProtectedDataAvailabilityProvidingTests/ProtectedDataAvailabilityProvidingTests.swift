#if canImport(UIKit)
import XCTest
import ProtectedDataAvailabilityProviding

final class ProtectedDataAvailabilityProvidingTests: XCTestCase {
    func testMockReturnsConfiguredState() {
        let provider = MockProtectedDataAvailabilityProvider(isProtectedDataAvailable: false)

        XCTAssertFalse(provider.isProtectedDataAvailable)
    }

    func testMockDefaultsToAvailable() {
        let provider = MockProtectedDataAvailabilityProvider()

        XCTAssertTrue(provider.isProtectedDataAvailable)
    }

    func testMockStartMonitoringFiresImmediatelyWithCurrentState() {
        let provider = MockProtectedDataAvailabilityProvider(isProtectedDataAvailable: false)
        var received: [Bool] = []

        provider.startMonitoringProtectedDataAvailability { received.append($0) }

        XCTAssertEqual(received, [false])
    }

    func testMockSimulateChangeDrivesOnChange() {
        let provider = MockProtectedDataAvailabilityProvider()
        var received: [Bool] = []
        provider.startMonitoringProtectedDataAvailability { received.append($0) }

        provider.simulateProtectedDataAvailabilityChange(to: false)

        XCTAssertEqual(received, [true, false])
        XCTAssertFalse(provider.isProtectedDataAvailable)
    }

    func testMockStopMonitoringStopsFurtherUpdates() {
        let provider = MockProtectedDataAvailabilityProvider()
        var received: [Bool] = []
        provider.startMonitoringProtectedDataAvailability { received.append($0) }
        provider.stopMonitoringProtectedDataAvailability()

        provider.simulateProtectedDataAvailabilityChange(to: false)

        XCTAssertEqual(received, [true])
    }

    /// Safe to exercise for real - isProtectedDataAvailable is a plain,
    /// non-prompting, nonisolated read, and constructing/tearing down the
    /// real notification observers never prompts or crashes either.
    /// Deliberately doesn't assert the value itself is `true`: unlike a real
    /// device, nothing guarantees a CI Simulator's data-protection state
    /// during an automated run - the same "call it, don't assert the
    /// runtime value" caution `BatteryStateProvidingTests` was corrected to
    /// use after a real CI run showed a device/Simulator-state assumption
    /// (isBatteryMonitoringEnabled reading back `true`) didn't hold.
    func testSystemProviderReadsAndMonitorsWithoutCrashing() {
        let provider = SystemProtectedDataAvailabilityProvider()

        _ = provider.isProtectedDataAvailable

        provider.startMonitoringProtectedDataAvailability { _ in }
        provider.stopMonitoringProtectedDataAvailability()
    }
}
#endif
