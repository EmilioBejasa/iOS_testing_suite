import XCTest
import WidgetTimelineTesting

/// Tests the real widget's timeline logic directly. `QuoteWidgetCore.swift`
/// is compiled directly into this target too (see project.yml's
/// `QuoteBoxTests.sources` - app-extension targets aren't linkable the way
/// `QuoteBox` itself is, so this can't be a plain `@testable import
/// QuoteBoxWidget`), so no import beyond `WidgetTimelineTesting` is needed.
/// Unlike `WidgetTimelineTestingTests.swift`'s synthetic
/// `DummyFavoritesProvider`, this exercises the actual provider
/// `QuoteBoxWidgetBundle` registers.
final class QuoteWidgetCoreTests: XCTestCase {
    private let suiteName = QuoteWidgetCore.appGroupSuiteName

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: QuoteWidgetCore.sharedQuoteKey)
        super.tearDown()
    }

    func testCollectTimelineReflectsSharedQuoteData() async throws {
        let payload = ["quote": "Test quote", "author": "Test Author"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        UserDefaults(suiteName: suiteName)?.set(data, forKey: QuoteWidgetCore.sharedQuoteKey)

        let timeline = await WidgetTimelineTesting.collectTimeline(from: QuoteWidgetCore(), in: ())

        XCTAssertEqual(timeline.entries.first?.quoteText, "Test quote")
        XCTAssertEqual(timeline.entries.first?.author, "Test Author")
    }

    func testCollectTimelineFallsBackToPlaceholderWhenNoSharedDataExists() async {
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: QuoteWidgetCore.sharedQuoteKey)

        let timeline = await WidgetTimelineTesting.collectTimeline(from: QuoteWidgetCore(), in: ())

        XCTAssertEqual(timeline.entries.first?.quoteText, QuoteWidgetCore.placeholderEntry.quoteText)
        XCTAssertEqual(timeline.entries.first?.author, QuoteWidgetCore.placeholderEntry.author)
    }
}
