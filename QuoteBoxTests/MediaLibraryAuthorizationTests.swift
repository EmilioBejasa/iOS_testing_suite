import XCTest
import MediaPlayer
import MediaLibraryAuthorization

final class MediaLibraryAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockMediaLibraryAuthorizer(status: .authorized, authorizationResult: .authorized)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorized)

        let result = await authorizer.requestAuthorization()
        XCTAssertEqual(result, .authorized)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockMediaLibraryAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Deliberately only reads status - never calls requestAuthorization()
    /// against the real authorizer. QuoteBox's Info.plist has no
    /// NSAppleMusicUsageDescription key, so requesting for real would crash
    /// the test host outright rather than just show a dialog XCTest can't
    /// dismiss - same reasoning CameraAuthorizationTests gives.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemMediaLibraryAuthorizer()

        _ = authorizer.currentAuthorizationStatus()
    }
}
