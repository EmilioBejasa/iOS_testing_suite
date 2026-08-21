#if canImport(AppTrackingTransparency)
import XCTest
import AppTrackingTransparency
import TrackingAuthorization

final class TrackingAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockTrackingAuthorizer(status: .authorized, authorizationResult: .authorized)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorized)

        let result = await authorizer.requestAuthorization()
        XCTAssertEqual(result, .authorized)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockTrackingAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Deliberately only reads status - never calls requestAuthorization()
    /// against the real authorizer. QuoteBox's Info.plist has no
    /// NSUserTrackingUsageDescription key, so requesting for real would crash
    /// the test host outright rather than just show a dialog XCTest can't
    /// dismiss - same reasoning CameraAuthorizationTests gives.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemTrackingAuthorizer()

        _ = authorizer.currentAuthorizationStatus()
    }
}
#endif
