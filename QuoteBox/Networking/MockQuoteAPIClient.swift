import Foundation

/// Deterministic stand-in for `QuoteAPIClient`, wired in by `QuoteBoxApp` based on
/// `--mock-success` / `--mock-error` launch arguments so XCUITests never depend on
/// live network conditions.
final class MockQuoteAPIClient: QuoteAPIClientProtocol {
    enum Mode {
        case success(Quote)
        case failure(APIError)
        /// Throws `.requestFailed` for the first `failures` calls, then returns
        /// `then` - lets a test drive `QuoteStore.fetchNewQuote()`'s
        /// retry-with-backoff deterministically without a real transient
        /// network failure.
        case failThenSucceed(failures: Int, then: Quote)
    }

    private let mode: Mode
    private var callCount = 0

    init(mode: Mode) {
        self.mode = mode
    }

    func fetchRandomQuote() async throws -> Quote {
        callCount += 1
        switch mode {
        case .success(let quote):
            return quote
        case .failure(let error):
            throw error
        case .failThenSucceed(let failures, let quote):
            if callCount <= failures {
                throw APIError.requestFailed
            }
            return quote
        }
    }

    static let defaultQuote = Quote(
        id: 1,
        quote: "The only way to do great work is to love what you do.",
        author: "Steve Jobs"
    )
}
