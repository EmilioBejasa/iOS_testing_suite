import Foundation

/// Not a protocol+real+fake module - there's nothing to fake, it's already a
/// pure, deterministic function - same "single-purpose utility" shape as
/// `SnapshotTesting`/`DeepLinkTesting`. Complements `NetworkStub`'s canned
/// HTTP responses with canned local JSON fixtures for tests that need
/// realistic decoded data without a network round trip at all.
public enum FixtureLoadingError: Error {
    case fixtureNotFound(String)
}

public enum JSONFixtureLoading {
    /// Looks up `"\(name).json"` in `bundle` and decodes it as `T`.
    public static func load<T: Decodable>(
        _ name: String,
        as type: T.Type,
        bundle: Bundle,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw FixtureLoadingError.fixtureNotFound(name)
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }
}
