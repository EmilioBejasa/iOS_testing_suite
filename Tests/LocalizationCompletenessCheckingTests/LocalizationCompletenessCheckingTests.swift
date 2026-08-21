import XCTest
import LocalizationCompletenessChecking

final class LocalizationCompletenessCheckingTests: XCTestCase {
    private func catalogURL() -> URL {
        Bundle.module.url(forResource: "sample-catalog", withExtension: "json")!
    }

    func testReportsNoGapsForFullyTranslatedKey() throws {
        let missing = try LocalizationCompletenessChecking.missingTranslations(
            inCatalogAt: catalogURL(),
            for: ["en", "es"]
        )

        XCTAssertFalse(missing.contains(MissingLocalization(key: "Hello, %@!", locale: "en")))
        XCTAssertFalse(missing.contains(MissingLocalization(key: "Hello, %@!", locale: "es")))
    }

    func testReportsGapForUntranslatedLocale() throws {
        let missing = try LocalizationCompletenessChecking.missingTranslations(
            inCatalogAt: catalogURL(),
            for: ["en", "es"]
        )

        XCTAssertTrue(missing.contains(MissingLocalization(key: "Settings", locale: "es")))
        XCTAssertFalse(missing.contains(MissingLocalization(key: "Settings", locale: "en")))
    }

    func testThrowsInvalidCatalogForMalformedJSON() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        try Data("{ \"notACatalog\": true }".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let attempt = { try LocalizationCompletenessChecking.missingTranslations(inCatalogAt: tempURL, for: ["en"]) }
        XCTAssertThrowsError(try attempt()) { error in
            guard case LocalizationCatalogError.invalidCatalog = error else {
                return XCTFail("Expected .invalidCatalog, got \(error)")
            }
        }
    }
}
