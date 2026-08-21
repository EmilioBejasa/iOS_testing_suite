import XCTest
import EventKit
import CalendarAuthorization

final class CalendarAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockCalendarAuthorizer(status: .fullAccess)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .fullAccess)

        let granted = await authorizer.requestAccess()
        XCTAssertTrue(granted)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockCalendarAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Deliberately only reads status - never calls requestAccess() against the
    /// real authorizer. That triggers an actual system permission alert when
    /// status is .notDetermined, which XCTest can't dismiss headlessly - and
    /// QuoteBox's Info.plist has no NSCalendarsFullAccessUsageDescription key,
    /// so it would crash the test host outright rather than just prompt.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemCalendarAuthorizer()

        _ = authorizer.currentAuthorizationStatus()
    }
}
