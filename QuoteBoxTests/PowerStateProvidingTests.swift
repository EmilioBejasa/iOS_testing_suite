import XCTest
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

    /// Safe to exercise for real - ProcessInfo.isLowPowerModeEnabled is a
    /// plain, synchronous, non-prompting read, no UIKit/MainActor concern.
    func testSystemProviderReadsWithoutCrashing() {
        let provider = SystemPowerStateProvider()

        _ = provider.isLowPowerModeEnabled
    }
}
