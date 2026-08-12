import XCTest
import EventKit
import RemindersAuthorization

final class RemindersAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockRemindersAuthorizer(status: .fullAccess)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .fullAccess)

        let granted = await authorizer.requestAccess()
        XCTAssertTrue(granted)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockRemindersAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Deliberately only reads status - never calls requestAccess() against
    /// the real authorizer, same reasoning CalendarAuthorizationTests gives
    /// (and that test passed CI clean with this exact treatment). QuoteBox's
    /// Info.plist has no NSRemindersFullAccessUsageDescription key, so
    /// requesting for real would crash the test host outright.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemRemindersAuthorizer()

        _ = authorizer.currentAuthorizationStatus()
    }
}
