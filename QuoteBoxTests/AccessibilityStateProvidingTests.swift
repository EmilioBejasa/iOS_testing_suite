import XCTest
import AccessibilityStateProviding

final class AccessibilityStateProvidingTests: XCTestCase {
    func testMockReturnsConfiguredValues() async {
        let provider = MockAccessibilityStateProvider(voiceOverRunning: true, reduceMotionEnabled: true)

        let voiceOver = await provider.isVoiceOverRunning()
        let reduceMotion = await provider.isReduceMotionEnabled()

        XCTAssertTrue(voiceOver)
        XCTAssertTrue(reduceMotion)
    }

    func testMockDefaultsToFalse() async {
        let provider = MockAccessibilityStateProvider()

        let voiceOver = await provider.isVoiceOverRunning()

        XCTAssertFalse(voiceOver)
    }

    /// Safe to exercise for real - UIAccessibility reads never prompt or
    /// crash, bridged through MainActor.run the same way
    /// SystemReviewRequester already does for UIApplication.shared.
    func testSystemProviderReadsWithoutCrashing() async {
        let provider = SystemAccessibilityStateProvider()

        _ = await provider.isVoiceOverRunning()
        _ = await provider.isReduceMotionEnabled()
    }
}
