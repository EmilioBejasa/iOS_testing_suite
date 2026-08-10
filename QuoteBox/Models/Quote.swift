import Foundation

/// Matches DummyJSON's random-quote response shape: https://dummyjson.com/quotes/random
/// A single flat object, unlike Weather's nested current/daily forecast payload —
/// deliberately different to prove NetworkStub isn't tied to any particular JSON shape.
struct Quote: Codable, Equatable, Identifiable {
    let id: Int
    let quote: String
    let author: String
}
