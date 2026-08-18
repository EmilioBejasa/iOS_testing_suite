import XCTest
import SnapshotTesting
@testable import QuoteBox

@MainActor
final class QuoteViewSnapshotTests: XCTestCase {
    func testQuoteContentViewLoaded() {
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")

        assertSnapshot(of: QuoteContentView(quote: quote), size: CGSize(width: 300, height: 150), named: "loaded")
    }

    /// Closes the SnapshotTesting scope note: `dynamicTypeSize` shipped without a
    /// committed reference image exercising it. Uses a taller frame than the
    /// default-size snapshot above - `.accessibility3` text needs materially more
    /// vertical room to lay out both lines without clipping.
    func testQuoteContentViewLoadedAccessibility3() {
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")

        assertSnapshot(
            of: QuoteContentView(quote: quote),
            size: CGSize(width: 300, height: 400),
            dynamicTypeSize: .accessibility3,
            named: "loaded-accessibility3"
        )
    }
}
