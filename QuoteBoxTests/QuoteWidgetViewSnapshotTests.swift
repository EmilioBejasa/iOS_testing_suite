import XCTest
import SnapshotTesting

/// `QuoteWidgetView` is a plain declarative view tree - a `VStack` of two
/// `Text` views, no `List`/`ScrollView`/`NavigationStack`/`TabView` - so it
/// snapshots the same straightforward way `QuoteContentView` already does.
/// Compiled directly into this target (see project.yml's QuoteBoxTests
/// sources comment) since app-extension targets aren't linkable.
@MainActor
final class QuoteWidgetViewSnapshotTests: XCTestCase {
    func testQuoteWidgetViewRendersQuoteAndAuthor() {
        let entry = QuoteWidgetEntry(
            date: Date(),
            quoteText: "The only way to do great work is to love what you do.",
            author: "Steve Jobs"
        )

        assertSnapshot(of: QuoteWidgetView(entry: entry), size: CGSize(width: 155, height: 155), named: "small")
    }
}
