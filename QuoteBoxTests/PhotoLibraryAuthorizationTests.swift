import XCTest
import Photos
import PhotoLibraryAuthorization

final class PhotoLibraryAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockPhotoLibraryAuthorizer(status: .authorized)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorized)

        let requestedStatus = await authorizer.requestAuthorization()
        XCTAssertEqual(requestedStatus, .authorized)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockPhotoLibraryAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Deliberately only reads status - never calls requestAuthorization() against
    /// the real authorizer. That triggers an actual system permission alert when
    /// status is .notDetermined, which XCTest can't dismiss headlessly and would
    /// hang the run rather than just fail it. Reading authorizationStatus is a
    /// plain synchronous property read that never prompts, so it's safe here.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemPhotoLibraryAuthorizer()

        // A fresh Simulator install starts .notDetermined; the only thing this
        // assertion proves is that reading status doesn't crash or hang - not
        // any particular status value.
        _ = authorizer.currentAuthorizationStatus()
    }
}
