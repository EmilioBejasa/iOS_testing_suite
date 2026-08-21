import XCTest
import CoreBluetooth
import BluetoothAuthorization

@available(iOS 13.1, *)
final class BluetoothAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() {
        let authorizer = MockBluetoothAuthorizer(status: .allowedAlways)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .allowedAlways)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockBluetoothAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Same reasoning as MotionAuthorizationTests: no explicit request call
    /// to avoid - Bluetooth prompts implicitly only when a CBCentralManager
    /// actually starts being used, not on a status read. Reading
    /// CBManager.authorization is a static, non-prompting call, safe to
    /// exercise for real.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemBluetoothAuthorizer()

        _ = authorizer.currentAuthorizationStatus()
    }
}
