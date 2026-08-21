import XCTest
import FeatureFlagging

final class FeatureFlaggingTests: XCTestCase {
    func testMockReturnsConfiguredOverride() {
        let flags = MockFeatureFlags(overrides: ["newQuoteLayout": true])

        XCTAssertTrue(flags.isEnabled("newQuoteLayout"))
    }

    func testMockDefaultsUnsetFlagToFalse() {
        let flags = MockFeatureFlags()

        XCTAssertFalse(flags.isEnabled("unsetFlag"))
    }

    /// Safe to exercise for real - UserDefaults reads/writes never prompt or
    /// crash, so unlike the permission-gated modules above there's no reason
    /// to avoid the real implementation here.
    func testSystemFeatureFlagsRoundTripsThroughUserDefaults() {
        let suiteName = "FeatureFlaggingTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let flags = SystemFeatureFlags(defaults: defaults)
        XCTAssertFalse(flags.isEnabled("newQuoteLayout"))

        defaults.set(true, forKey: "featureFlag.newQuoteLayout")
        XCTAssertTrue(flags.isEnabled("newQuoteLayout"))
    }
}
