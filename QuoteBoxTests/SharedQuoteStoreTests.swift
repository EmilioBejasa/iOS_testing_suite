import XCTest
@testable import QuoteBox

/// `SystemSharedQuoteStore` is the only production caller of `save(_:)` -
/// every test-constructed `QuoteStore` elsewhere in this target uses
/// `NoOpSharedQuoteWriter` instead, specifically so it doesn't write into the
/// real `group.com.quotebox.qa` suite `QuoteWidgetCoreTests` seeds and reads
/// from directly (see that file's own comment on the CI flake this caused).
/// This test exercises the real type the same way `UserDefaultsStoreTests`
/// does - a throwaway, UUID-suffixed suite name instead of the real App
/// Group - so it can't race or collide with that suite.
final class SharedQuoteStoreTests: XCTestCase {
    func testSaveWritesQuoteAndAuthorToItsSuite() throws {
        let suiteName = "com.quotebox.qa.tests.sharedquotestore.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }

        let store = SystemSharedQuoteStore(suiteName: suiteName)
        let quote = Quote(id: 1, quote: "The only way to do great work is to love what you do.", author: "Steve Jobs")

        store.save(quote)

        let data = try XCTUnwrap(defaults?.data(forKey: SystemSharedQuoteStore.sharedQuoteKey))
        let payload = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(payload?["quote"], quote.quote)
        XCTAssertEqual(payload?["author"], quote.author)
    }

    func testSaveOverwritesAPreviouslySavedQuote() throws {
        let suiteName = "com.quotebox.qa.tests.sharedquotestore.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }

        let store = SystemSharedQuoteStore(suiteName: suiteName)
        store.save(Quote(id: 1, quote: "First quote.", author: "First Author"))
        store.save(Quote(id: 2, quote: "Second quote.", author: "Second Author"))

        let data = try XCTUnwrap(defaults?.data(forKey: SystemSharedQuoteStore.sharedQuoteKey))
        let payload = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(payload?["quote"], "Second quote.")
        XCTAssertEqual(payload?["author"], "Second Author")
    }
}
