import XCTest
import Security
import KeychainStore

/// Round-trips both implementations against the same behavior contract: the real
/// `SystemKeychainStore` against the Simulator's actual Keychain (proving the
/// wrapper genuinely works, not just its fake), and `InMemoryKeychainStore`
/// (proving interchangeability). Not wired into a QuoteBox feature — a public
/// quotes app has no natural secret to store, so this is validated directly here
/// instead of through the app's UI.
final class KeychainStoreTests: XCTestCase {
    func testSystemStoreRoundTripsSaveLoadDelete() throws {
        do {
            try assertRoundTrips(SystemKeychainStore(service: "com.quotebox.qa.tests"))
        } catch KeychainError.unexpectedStatus(let status) where status == errSecMissingEntitlement {
            // reusable-test.yml runs `xcodebuild test` with CODE_SIGNING_ALLOWED=NO
            // so any consumer app can run CI without a signing identity - but that
            // also means the keychain-access-groups entitlement never gets embedded
            // in the built binary, and real Keychain access requires it even on the
            // Simulator. This isn't a bug in SystemKeychainStore: it validates real
            // Keychain access correctly in a properly signed environment (a real
            // device, or CI with signing configured) - just not this one.
            throw XCTSkip(
                "Skipped: this CI run builds with CODE_SIGNING_ALLOWED=NO, so the keychain-access-groups " +
                "entitlement isn't embedded and real Keychain access isn't available."
            )
        }
    }

    func testInMemoryStoreRoundTripsSaveLoadDelete() throws {
        try assertRoundTrips(InMemoryKeychainStore())
    }

    /// Uses plain `try` statements rather than `XCTAssertNil(try ...)` so a thrown
    /// error propagates out of this function instead of being swallowed into a
    /// recorded test failure — callers need the real error to decide whether to
    /// skip (see the missing-entitlement handling above).
    private func assertRoundTrips(_ store: KeychainStoring) throws {
        let key = "test.key.\(UUID().uuidString)"
        let data = Data("secret value".utf8)

        let initial = try store.load(for: key)
        XCTAssertNil(initial)

        try store.save(data, for: key)
        let saved = try store.load(for: key)
        XCTAssertEqual(saved, data)

        let updated = Data("updated value".utf8)
        try store.save(updated, for: key)
        let reloaded = try store.load(for: key)
        XCTAssertEqual(reloaded, updated)

        try store.delete(for: key)
        let afterDelete = try store.load(for: key)
        XCTAssertNil(afterDelete)
    }
}
