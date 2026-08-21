#if canImport(UIKit)
import XCTest
import UIKit
import HapticFeedbackProviding

final class HapticFeedbackProvidingTests: XCTestCase {
    func testMockRecordsRequestedStyles() async {
        let provider = MockHapticFeedbackProvider()

        await provider.impact(style: .light)
        await provider.impact(style: .heavy)

        XCTAssertEqual(provider.impactStyles, [.light, .heavy])
    }

    func testMockStartsEmpty() {
        let provider = MockHapticFeedbackProvider()

        XCTAssertTrue(provider.impactStyles.isEmpty)
    }

    /// Safe to exercise for real - haptics silently no-op on the Simulator
    /// (no hardware), bridged through MainActor.run the same way
    /// SystemReviewRequester already does for UIApplication.shared.
    func testSystemProviderFiresWithoutCrashing() async {
        let provider = SystemHapticFeedbackProvider()

        await provider.impact(style: .medium)
    }
}
#endif
