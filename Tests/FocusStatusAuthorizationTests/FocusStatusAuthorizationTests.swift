#if os(iOS)
import XCTest
import Intents
import FocusStatusAuthorization

@available(iOS 15.0, *)
final class FocusStatusAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockFocusStatusAuthorizer(status: .authorized, authorizationResult: .authorized)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorized)

        let result = await authorizer.requestAuthorization()
        XCTAssertEqual(result, .authorized)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockFocusStatusAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Unlike most other authorization modules' real-side test, this
    /// doesn't even call the normally-safe status read. INFocusStatusCenter
    /// is in the same Intents-framework family as INPreferences (Siri) and
    /// requires the "Communication Notifications" capability just to use the
    /// class - same "documented risk, untested real path" treatment
    /// SiriAuthorizationTests already learned to give INPreferences, applied
    /// here proactively rather than re-discovered via another failed CI run.
    func testSystemAuthorizerConstructsWithoutCrashing() {
        _ = SystemFocusStatusAuthorizer()
    }
}
#endif
