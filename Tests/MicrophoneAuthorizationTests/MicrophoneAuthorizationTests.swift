import XCTest
import AVFoundation
import MicrophoneAuthorization

final class MicrophoneAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockMicrophoneAuthorizer(status: .authorized)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorized)

        let granted = await authorizer.requestAccess()
        XCTAssertTrue(granted)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockMicrophoneAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Same reasoning as CameraAuthorizationTests: never calls requestAccess()
    /// against the real authorizer, since QuoteBox's Info.plist has no
    /// NSMicrophoneUsageDescription key - requesting for real would crash the
    /// test host, not just prompt.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemMicrophoneAuthorizer()

        _ = authorizer.currentAuthorizationStatus()
    }
}
