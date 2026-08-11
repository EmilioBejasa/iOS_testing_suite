import XCTest
import CoreLocation
import LocationAuthorization

final class LocationAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockLocationAuthorizer(status: .authorizedWhenInUse)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorizedWhenInUse)

        let requestedStatus = await authorizer.requestWhenInUseAuthorization()
        XCTAssertEqual(requestedStatus, .authorizedWhenInUse)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockLocationAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Deliberately only reads status - never calls requestWhenInUseAuthorization()
    /// against the real authorizer. That triggers an actual system permission
    /// alert when status is .notDetermined, which XCTest can't dismiss headlessly
    /// and would hang the run rather than just fail it. Reading authorizationStatus
    /// is a plain synchronous property read that never prompts, so it's safe here.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemLocationAuthorizer()

        // A fresh Simulator install starts .notDetermined; the only thing this
        // assertion proves is that reading status doesn't crash or hang - not
        // any particular status value.
        _ = authorizer.currentAuthorizationStatus()
    }
}
