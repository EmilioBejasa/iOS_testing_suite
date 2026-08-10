import Foundation

protocol FavoritesStoring {
    func loadFavorites() -> [Quote]
    func save(_ favorites: [Quote])
}

/// In-memory stand-in used for deterministic unit tests and UI-test launch modes.
final class InMemoryFavoritesStore: FavoritesStoring {
    private(set) var favorites: [Quote]

    init(seed: [Quote] = []) {
        self.favorites = seed
    }

    func loadFavorites() -> [Quote] { favorites }
    func save(_ favorites: [Quote]) { self.favorites = favorites }
}
