import XCTest
import SnapshotTesting
@testable import QuoteBox

@MainActor
final class QuoteViewSnapshotTests: XCTestCase {
    func testQuoteContentViewLoaded() {
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")

        assertSnapshot(of: QuoteContentView(quote: quote), size: CGSize(width: 300, height: 150), named: "loaded")
    }
}
