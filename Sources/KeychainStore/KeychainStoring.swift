import Foundation

/// Abstracts Keychain-backed persistence so app code isn't tied to `Security`
/// framework calls directly — the same protocol+real+fake shape as a typical
/// app-level `FavoritesStoring`-style abstraction, just reusable across apps.
public protocol KeychainStoring {
    func save(_ data: Data, for key: String) throws
    func load(for key: String) throws -> Data?
    func delete(for key: String) throws
}

public enum KeychainError: Error, Equatable {
    case unexpectedStatus(OSStatus)
}

/// Persists to the real Keychain via `kSecClassGenericPassword`, scoped by
/// `service` so multiple apps/kinds of secrets on the same device don't collide.
public final class SystemKeychainStore: KeychainStoring {
    private let service: String

    public init(service: String) {
        self.service = service
    }

    public func save(_ data: Data, for key: String) throws {
        try? delete(for: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }

    public func load(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
        return result as? Data
    }

    public func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

/// In-memory stand-in for deterministic unit tests — no real Keychain access.
public final class InMemoryKeychainStore: KeychainStoring {
    private var storage: [String: Data] = [:]

    public init() {}

    public func save(_ data: Data, for key: String) throws {
        storage[key] = data
    }

    public func load(for key: String) throws -> Data? {
        storage[key]
    }

    public func delete(for key: String) throws {
        storage.removeValue(forKey: key)
    }
}
