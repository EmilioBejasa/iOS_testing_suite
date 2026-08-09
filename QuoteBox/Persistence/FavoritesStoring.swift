import Foundation

protocol FavoritesStoring {
    func loadFavorites() -> [Quote]
    func save(_ favorites: [Quote])
}

/// Persists favorites to disk via UserDefaults.
final class UserDefaultsFavoritesStore: FavoritesStoring {
    private let defaults: UserDefaults
    private let key = "favorites.quotes"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadFavorites() -> [Quote] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Quote].self, from: data)) ?? []
    }

    func save(_ favorites: [Quote]) {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        defaults.set(data, forKey: key)
    }
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
