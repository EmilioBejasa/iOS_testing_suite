import XCTest
import UserDefaultsStore

/// Round-trips both implementations against the same behavior contract: the real
/// `SystemUserDefaultsStore` against a dedicated test suite (so it can't collide
/// with other tests' keys or leak into `.standard`), and `InMemoryUserDefaultsStore`
/// (proving interchangeability). Unlike `KeychainStoreTests`, there's no
/// entitlement/signing concern here, so no skip path is needed.
final class UserDefaultsStoreTests: XCTestCase {
    func testSystemStoreRoundTripsIntegersAndBools() {
        let suiteName = "com.quotebox.qa.tests.userdefaults.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }

        assertRoundTrips(SystemUserDefaultsStore(suiteName: suiteName))
    }

    func testInMemoryStoreRoundTripsIntegersAndBools() {
        assertRoundTrips(InMemoryUserDefaultsStore())
    }

    private func assertRoundTrips(_ store: UserDefaultsStoring) {
        let intKey = "test.int.\(UUID().uuidString)"
        let boolKey = "test.bool.\(UUID().uuidString)"

        XCTAssertEqual(store.integer(for: intKey), 0)
        XCTAssertEqual(store.bool(for: boolKey), false)

        store.setInteger(3, for: intKey)
        store.setBool(true, for: boolKey)

        XCTAssertEqual(store.integer(for: intKey), 3)
        XCTAssertEqual(store.bool(for: boolKey), true)

        store.setInteger(4, for: intKey)
        XCTAssertEqual(store.integer(for: intKey), 4)
    }
}
