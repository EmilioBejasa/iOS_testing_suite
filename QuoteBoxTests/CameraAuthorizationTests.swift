import XCTest
import AVFoundation
import CameraAuthorization

final class CameraAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockCameraAuthorizer(status: .authorized)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorized)

        let granted = await authorizer.requestAccess()
        XCTAssertTrue(granted)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockCameraAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Deliberately only reads status - never calls requestAccess() against the
    /// real authorizer. That triggers an actual system permission alert when
    /// status is .notDetermined, which XCTest can't dismiss headlessly and would
    /// hang the run rather than just fail it - the same reasoning
    /// ContactsAuthorizationTests gives. Worse here: QuoteBox's Info.plist has
    /// no NSCameraUsageDescription key, so requesting for real wouldn't just
    /// prompt, it would crash the test host outright.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemCameraAuthorizer()

        // A fresh Simulator install starts .notDetermined; the only thing this
        // assertion proves is that reading status doesn't crash or hang - not
        // any particular status value.
        _ = authorizer.currentAuthorizationStatus()
    }
}
