import XCTest
import Speech
import SpeechRecognitionAuthorization

final class SpeechRecognitionAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockSpeechRecognitionAuthorizer(status: .authorized, authorizationResult: .authorized)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorized)

        let result = await authorizer.requestAuthorization()
        XCTAssertEqual(result, .authorized)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockSpeechRecognitionAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Same reasoning as CameraAuthorizationTests/MicrophoneAuthorizationTests:
    /// never calls requestAuthorization() against the real authorizer, since
    /// QuoteBox's Info.plist has no NSSpeechRecognitionUsageDescription key -
    /// requesting for real would crash the test host, not just prompt.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemSpeechRecognitionAuthorizer()

        _ = authorizer.currentAuthorizationStatus()
    }
}
