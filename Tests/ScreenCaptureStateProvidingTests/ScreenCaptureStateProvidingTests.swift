#if canImport(UIKit)
import XCTest
import ScreenCaptureStateProviding

final class ScreenCaptureStateProvidingTests: XCTestCase {
    func testMockReturnsConfiguredState() async {
        let provider = MockScreenCaptureStateProvider(isCaptured: true)

        let captured = await provider.isScreenCaptured()

        XCTAssertTrue(captured)
    }

    func testMockDefaultsToNotCaptured() async {
        let provider = MockScreenCaptureStateProvider()

        let captured = await provider.isScreenCaptured()

        XCTAssertFalse(captured)
    }

    func testMockStartMonitoringFiresImmediatelyWithCurrentState() {
        let provider = MockScreenCaptureStateProvider(isCaptured: true)
        var received: [Bool] = []

        provider.startMonitoringScreenCapture { received.append($0) }

        XCTAssertEqual(received, [true])
    }

    func testMockSimulateScreenCaptureChangeDrivesOnChange() {
        let provider = MockScreenCaptureStateProvider()
        var received: [Bool] = []
        provider.startMonitoringScreenCapture { received.append($0) }

        provider.simulateScreenCaptureChange(to: true)

        XCTAssertEqual(received, [false, true])
    }

    func testMockStopMonitoringStopsFurtherUpdates() {
        let provider = MockScreenCaptureStateProvider()
        var received: [Bool] = []
        provider.startMonitoringScreenCapture { received.append($0) }
        provider.stopMonitoringScreenCapture()

        provider.simulateScreenCaptureChange(to: true)

        XCTAssertEqual(received, [false])
    }

    /// Safe to exercise for real - UIScreen.isCaptured is a non-prompting
    /// read (deprecated but functional, see the module's scope note), and
    /// constructing/tearing down the real notification observer never
    /// prompts or crashes either, even though nothing in CI can force an
    /// actual screen recording to start and fire it.
    func testSystemProviderReadsAndMonitorsWithoutCrashing() async {
        let provider = SystemScreenCaptureStateProvider()

        _ = await provider.isScreenCaptured()

        provider.startMonitoringScreenCapture { _ in }
        provider.stopMonitoringScreenCapture()
    }
}
#endif
