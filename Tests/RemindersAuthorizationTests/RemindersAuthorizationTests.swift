import XCTest
import EventKit
import RemindersAuthorization

/// This standalone SwiftPM test target inherits Package.swift's package-wide
/// iOS 13/macOS 13 floor by default (unlike when this test ran inside
/// QuoteBoxTests against QuoteBox's iOS 17 deployment target), so it needs
/// the same `@available(iOS 17.0, macOS 14.0, *)` floor as
/// `SystemRemindersAuthorizer` itself.
@available(iOS 17.0, macOS 14.0, *)
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
