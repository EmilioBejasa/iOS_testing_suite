#if os(iOS)
import XCTest
import Intents
import SiriAuthorization

final class SiriAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockSiriAuthorizer(status: .authorized, authorizationResult: .authorized)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorized)

        let result = await authorizer.requestAuthorization()
        XCTAssertEqual(result, .authorized)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockSiriAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Unlike every other authorization module's real-side test, this
    /// doesn't even call the normally-safe status read. `INPreferences` is
    /// stricter than Contacts/Location/Photo/Camera/Mic/Speech/Calendar/
    /// Tracking: merely *using the class* - not just requesting access -
    /// requires the `com.apple.developer.siri` entitlement QuoteBox doesn't
    /// have, and crashes immediately without it
    /// (`NSInternalInconsistencyException`, discovered via a failed CI run,
    /// not assumed in advance). Same "documented risk, untested real path"
    /// treatment `HealthAuthorizationTests`/`CloudKitAccountCheckingTests`
    /// give their real authorizers: only construct it, never call a method.
    func testSystemAuthorizerConstructsWithoutCrashing() {
        _ = SystemSiriAuthorizer()
    }
}
#endif
