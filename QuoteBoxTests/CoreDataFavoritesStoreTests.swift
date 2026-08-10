import XCTest
import CoreDataTestSupport
@testable import QuoteBox

final class CoreDataFavoritesStoreTests: XCTestCase {
    private func makeStore() -> CoreDataFavoritesStore {
        let container = InMemoryPersistentContainer.make(
            modelName: "QuoteBox",
            bundle: Bundle(for: CoreDataFavoritesStore.self)
        )
        return CoreDataFavoritesStore(container: container)
    }

    func testSaveAndLoadRoundTripsFavorites() {
        let store = makeStore()
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")

        store.save([quote])

        XCTAssertEqual(store.loadFavorites(), [quote])
    }

    func testSaveReplacesPreviousFavorites() {
        let store = makeStore()
        store.save([Quote(id: 1, quote: "First", author: "A")])

        store.save([Quote(id: 2, quote: "Second", author: "B")])

        XCTAssertEqual(store.loadFavorites(), [Quote(id: 2, quote: "Second", author: "B")])
    }

    func testLoadFavoritesReturnsEmptyWhenNoneSaved() {
        let store = makeStore()

        XCTAssertEqual(store.loadFavorites(), [])
    }
}
