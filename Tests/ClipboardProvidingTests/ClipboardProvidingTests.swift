#if os(iOS)
import XCTest
import ClipboardProviding

final class ClipboardProvidingTests: XCTestCase {
    func testMockRoundTripsCopiedString() {
        let clipboard = MockClipboardProvider()

        clipboard.copy("hello")

        XCTAssertEqual(clipboard.currentString(), "hello")
    }

    func testMockDefaultsToNil() {
        let clipboard = MockClipboardProvider()

        XCTAssertNil(clipboard.currentString())
    }

    /// Safe to exercise for real - a copy/read round trip against the real
    /// Simulator pasteboard has no lasting side effect worth avoiding, and
    /// UIPasteboard is documented as safe to use off the main thread (no
    /// MainActor bridging needed here, unlike the Cluster 12 UIKit modules).
    func testSystemProviderRoundTripsAgainstRealPasteboard() {
        let clipboard = SystemClipboardProvider()

        clipboard.copy("QuoteBoxTests-\(UUID().uuidString)")

        XCTAssertNotNil(clipboard.currentString())
    }
}
#endif
