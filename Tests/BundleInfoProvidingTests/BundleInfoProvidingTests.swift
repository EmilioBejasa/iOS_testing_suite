import XCTest
import BundleInfoProviding

final class BundleInfoProvidingTests: XCTestCase {
    func testMockReturnsConfiguredValues() {
        let provider = MockBundleInfoProvider(appVersion: "2.3", buildNumber: "42")

        XCTAssertEqual(provider.appVersion, "2.3")
        XCTAssertEqual(provider.buildNumber, "42")
    }

    func testMockDefaults() {
        let provider = MockBundleInfoProvider()

        XCTAssertEqual(provider.appVersion, "1.0")
        XCTAssertEqual(provider.buildNumber, "1")
    }

    /// Safe to exercise for real - Bundle.infoDictionary is a plain,
    /// synchronous Foundation read. Only asserts non-empty, not exact
    /// values, since this reads whatever the test bundle's own Info.plist
    /// reports rather than a fixed value.
    func testSystemProviderReadsRealBundleWithoutCrashing() {
        let provider = SystemBundleInfoProvider(bundle: Bundle(for: BundleInfoProvidingTests.self))

        XCTAssertFalse(provider.appVersion.isEmpty)
        XCTAssertFalse(provider.buildNumber.isEmpty)
    }
}
