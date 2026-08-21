import XCTest
import EventKit
import CalendarAuthorization

/// This standalone SwiftPM test target inherits Package.swift's package-wide
/// iOS 13/macOS 13 floor by default (unlike when this test ran inside
/// QuoteBoxTests against QuoteBox's iOS 17 deployment target), so it needs
/// the same `@available(iOS 17.0, macOS 14.0, *)` floor as
/// `SystemCalendarAuthorizer` itself.
@available(iOS 17.0, macOS 14.0, *)
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
