import Foundation

enum APIError: Error, Equatable, LocalizedError {
    case invalidURL
    case requestFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .requestFailed:
            return "Couldn't reach the quote service. Check your connection and try again."
        case .decodingFailed:
            return "Received an unexpected response."
        }
    }
}

protocol QuoteAPIClientProtocol {
    func fetchRandomQuote() async throws -> Quote
}

/// Talks to DummyJSON (https://dummyjson.com), a free API commonly used for demos/tests.
struct QuoteAPIClient: QuoteAPIClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchRandomQuote() async throws -> Quote {
        guard let url = URL(string: "https://dummyjson.com/quotes/random") else {
            throw APIError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.requestFailed
        }
        do {
            return try JSONDecoder().decode(Quote.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }
}
