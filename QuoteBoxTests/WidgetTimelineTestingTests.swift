import XCTest
import CoreDataTestSupport
import WidgetKit
import WidgetTimelineTesting
@testable import QuoteBox

@available(iOS 14.0, *)
final class WidgetTimelineTestingTests: XCTestCase {
    private struct FavoriteCountEntry: TimelineEntry {
        let date: Date
        let favoriteCount: Int
    }

    /// Not a real widget - QuoteBox has no widget extension target (see
    /// this module's Scope note in the README) - but its data source is
    /// real: it reads from the same `CoreDataFavoritesStore` fixture
    /// `CoreDataFavoritesStoreTests.swift` uses, so timeline entries reflect
    /// real (test) favorite-quote data even though nothing renders them as
    /// widget UI.
    private struct DummyFavoritesProvider: TimelineProviding {
        let favoritesStore: CoreDataFavoritesStore

        func getTimeline(in context: Void, completion: @escaping (Timeline<FavoriteCountEntry>) -> Void) {
            let entry = FavoriteCountEntry(date: Date(), favoriteCount: favoritesStore.loadFavorites().count)
            completion(Timeline(entries: [entry], policy: .never))
        }
    }

    func testCollectTimelineReflectsRealFavoritesStoreData() async {
        let container = InMemoryPersistentContainer.make(
            modelName: "QuoteBox",
            bundle: Bundle(for: CoreDataFavoritesStore.self)
        )
        let favoritesStore = CoreDataFavoritesStore(container: container)
        favoritesStore.save([
            Quote(id: 1, quote: "Test quote", author: "Test Author"),
            Quote(id: 2, quote: "Another quote", author: "Another Author")
        ])
        let provider = DummyFavoritesProvider(favoritesStore: favoritesStore)

        let timeline = await WidgetTimelineTesting.collectTimeline(from: provider, in: ())

        XCTAssertEqual(timeline.entries.first?.favoriteCount, 2)
    }
}
