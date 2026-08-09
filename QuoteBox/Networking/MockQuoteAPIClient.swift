import Foundation

/// Deterministic stand-in for `QuoteAPIClient`, wired in by `QuoteBoxApp` based on
/// `--mock-success` / `--mock-error` launch arguments so XCUITests never depend on
/// live network conditions.
final class MockQuoteAPIClient: QuoteAPIClientProtocol {
    enum Mode {
        case success(Quote)
        case failure(APIError)
    }

    private let mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    func fetchRandomQuote() async throws -> Quote {
        switch mode {
        case .success(let quote):
            return quote
        case .failure(let error):
            throw error
        }
    }

    static let defaultQuote = Quote(
        id: 1,
        quote: "The only way to do great work is to love what you do.",
        author: "Steve Jobs"
    )
}
