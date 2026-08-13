import XCTest
import CoreDataTestSupport
import MemoryLeakDetection
import PurchaseSupport
@testable import QuoteBox

@MainActor
final class MemoryLeakDetectionTests: XCTestCase {
    func testQuoteStoreDeallocatesAfterFetching() async {
        var store: QuoteStore? = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(MockQuoteAPIClient.defaultQuote)),
            favoritesStore: InMemoryFavoritesStore()
        )
        trackForMemoryLeaks(store!)

        await store!.fetchNewQuote()

        store = nil
    }

    func testTipJarStoreDeallocatesAfterPurchasing() async {
        var store: TipJarStore? = TipJarStore(purchaseManager: MockPurchaseManager())
        trackForMemoryLeaks(store!)

        await store!.purchaseTip()

        store = nil
    }

    func testCoreDataFavoritesStoreDeallocatesAfterSaving() {
        let container = InMemoryPersistentContainer.make(
            modelName: "QuoteBox",
            bundle: Bundle(for: CoreDataFavoritesStore.self)
        )
        var store: CoreDataFavoritesStore? = CoreDataFavoritesStore(container: container)
        trackForMemoryLeaks(store!)

        store!.save([Quote(id: 1, quote: "Test quote", author: "Test Author")])

        store = nil
    }
}
