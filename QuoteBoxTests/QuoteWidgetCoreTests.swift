import XCTest
import WidgetTimelineTesting
@testable import QuoteBoxWidget

/// Tests the real widget's timeline logic directly (`QuoteWidgetCore`,
/// imported from the `QuoteBoxWidget` extension target) - unlike
/// `WidgetTimelineTestingTests.swift`'s synthetic `DummyFavoritesProvider`,
/// this exercises the actual provider `QuoteBoxWidgetBundle` registers.
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
