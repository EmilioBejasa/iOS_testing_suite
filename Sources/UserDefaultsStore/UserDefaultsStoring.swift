import Foundation

/// Abstracts `UserDefaults`-backed persistence so app code isn't tied to
/// `UserDefaults` calls directly — the same protocol+real+fake shape as
/// `KeychainStoring`. Scoped to the two most common `UserDefaults` use cases
/// (counters, flags) rather than a generic `Codable` wrapper.
public protocol UserDefaultsStoring {
    func integer(for key: String) -> Int
    func setInteger(_ value: Int, for key: String)
    func bool(for key: String) -> Bool
    func setBool(_ value: Bool, for key: String)
}

/// Persists to real `UserDefaults`, optionally scoped to a suite so tests or app
/// extensions don't collide with `.standard`.
public final class SystemUserDefaultsStore: UserDefaultsStoring {
    private let defaults: UserDefaults

    public init(suiteName: String? = nil) {
        defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    public func integer(for key: String) -> Int {
        defaults.integer(forKey: key)
    }

    public func setInteger(_ value: Int, for key: String) {
        defaults.set(value, forKey: key)
    }

    public func bool(for key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    public func setBool(_ value: Bool, for key: String) {
        defaults.set(value, forKey: key)
    }
}

/// In-memory stand-in for deterministic unit tests — no real `UserDefaults`
/// access, and nothing persists between launches.
public final class InMemoryUserDefaultsStore: UserDefaultsStoring {
    private var ints: [String: Int] = [:]
    private var bools: [String: Bool] = [:]

    public init() {}

    public func integer(for key: String) -> Int {
        ints[key] ?? 0
    }

    public func setInteger(_ value: Int, for key: String) {
        ints[key] = value
    }

    public func bool(for key: String) -> Bool {
        bools[key] ?? false
    }

    public func setBool(_ value: Bool, for key: String) {
        bools[key] = value
    }
}
