import XCTest
import SwiftData
import SwiftDataTestSupport

@available(iOS 17.0, macOS 14.0, *)
@Model
final class SwiftDataTestSupportFixtureItem {
    var name: String

    init(name: String) {
        self.name = name
    }
}

/// Kit-level only - same reasoning `CoreDataTestSupport` gives for staying
/// kit-level in every other regard except its own module: QuoteBox already
/// persists favorites through Core Data, and a second, parallel SwiftData
/// feature for the same data would be duplicative, not a natural consumer.
/// Exercised here against a throwaway `@Model` type defined just for this
/// test file instead, the same "no natural QuoteBox need" treatment
/// `KeychainStore`/`LocationAuthorization` give their own kit-level-only
/// modules. Matches `InMemoryModelContainer`'s own `@available(iOS 17.0,
/// macOS 14.0, *)` floor - this standalone SwiftPM test target inherits
/// Package.swift's package-wide iOS 13/macOS 13 floor by default, unlike
/// when this test ran inside QuoteBoxTests against QuoteBox's iOS 17
/// deployment target.
@available(iOS 17.0, macOS 14.0, *)
final class SwiftDataTestSupportTests: XCTestCase {
    func testMakeReturnsWorkingInMemoryContainer() throws {
        let container = InMemoryModelContainer.make(for: [SwiftDataTestSupportFixtureItem.self])
        let context = ModelContext(container)

        context.insert(SwiftDataTestSupportFixtureItem(name: "test"))
        try context.save()

        let items = try context.fetch(FetchDescriptor<SwiftDataTestSupportFixtureItem>())
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "test")
    }

    func testEachContainerStartsEmptyWithNoSharedState() throws {
        let firstContainer = InMemoryModelContainer.make(for: [SwiftDataTestSupportFixtureItem.self])
        let firstContext = ModelContext(firstContainer)
        firstContext.insert(SwiftDataTestSupportFixtureItem(name: "first"))
        try firstContext.save()

        let secondContainer = InMemoryModelContainer.make(for: [SwiftDataTestSupportFixtureItem.self])
        let secondContext = ModelContext(secondContainer)

        let items = try secondContext.fetch(FetchDescriptor<SwiftDataTestSupportFixtureItem>())
        XCTAssertTrue(items.isEmpty)
    }
}
