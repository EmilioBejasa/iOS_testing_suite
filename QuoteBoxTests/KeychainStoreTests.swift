import XCTest
import KeychainStore

/// Round-trips both implementations against the same behavior contract: the real
/// `SystemKeychainStore` against the Simulator's actual Keychain (proving the
/// wrapper genuinely works, not just its fake), and `InMemoryKeychainStore`
/// (proving interchangeability). Not wired into a QuoteBox feature — a public
/// quotes app has no natural secret to store, so this is validated directly here
/// instead of through the app's UI.
final class KeychainStoreTests: XCTestCase {
    func testSystemStoreRoundTripsSaveLoadDelete() throws {
        try assertRoundTrips(SystemKeychainStore(service: "com.quotebox.qa.tests"))
    }

    func testInMemoryStoreRoundTripsSaveLoadDelete() throws {
        try assertRoundTrips(InMemoryKeychainStore())
    }

    private func assertRoundTrips(_ store: KeychainStoring) throws {
        let key = "test.key.\(UUID().uuidString)"
        let data = "secret value".data(using: .utf8)!

        XCTAssertNil(try store.load(for: key))

        try store.save(data, for: key)
        XCTAssertEqual(try store.load(for: key), data)

        let updated = "updated value".data(using: .utf8)!
        try store.save(updated, for: key)
        XCTAssertEqual(try store.load(for: key), updated)

        try store.delete(for: key)
        XCTAssertNil(try store.load(for: key))
    }
}
