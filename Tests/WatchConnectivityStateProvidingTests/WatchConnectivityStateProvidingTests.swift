#if os(iOS)
import XCTest
import WatchConnectivityStateProviding

final class WatchConnectivityStateProvidingTests: XCTestCase {
    func testMockReturnsConfiguredValues() {
        let provider = MockWatchConnectivityStateProvider(supported: true, paired: true, watchAppInstalled: true)

        XCTAssertTrue(provider.isSupported())
        XCTAssertTrue(provider.isPaired())
        XCTAssertTrue(provider.isWatchAppInstalled())
    }

    func testMockDefaults() {
        let provider = MockWatchConnectivityStateProvider()

        XCTAssertTrue(provider.isSupported())
        XCTAssertFalse(provider.isPaired())
        XCTAssertFalse(provider.isWatchAppInstalled())
    }

    /// Safe to exercise for real on every device, including this repo's CI
    /// iPad job - WatchConnectivity has no permission prompt, and every
    /// real access guards with WCSession.isSupported() first (confirmed via
    /// WebSearch: WCSession isn't supported on iPad), so this is expected to
    /// gracefully report false there rather than crash.
    func testSystemProviderReadsWithoutCrashing() {
        let provider = SystemWatchConnectivityStateProvider()

        _ = provider.isSupported()
        _ = provider.isPaired()
        _ = provider.isWatchAppInstalled()
    }
}
#endif
