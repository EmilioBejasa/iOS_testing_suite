import XCTest
@testable import QuoteBox

/// Hits the real DummyJSON API instead of a stub. Excluded from the default
/// `xcodebuild test` run (see ci.yml's `skip_testing`) and run separately via
/// reusable-live-contract.yml so a live network hiccup can't block CI.
final class DummyJSONLiveContractTests: XCTestCase {
    func testFetchRandomQuoteAgainstRealAPI() async throws {
        let client = QuoteAPIClient()
        let quote = try await client.fetchRandomQuote()

        XCTAssertFalse(quote.quote.isEmpty)
        XCTAssertFalse(quote.author.isEmpty)
    }
}
