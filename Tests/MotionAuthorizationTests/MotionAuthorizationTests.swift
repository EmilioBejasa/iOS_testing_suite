#if canImport(CoreMotion)
import XCTest
import CoreMotion
import MotionAuthorization

final class MotionAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() {
        let authorizer = MockMotionAuthorizer(status: .authorized)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorized)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockMotionAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Unlike every request-based permission module, there's no explicit
    /// request call to avoid here - Core Motion prompts implicitly only when
    /// activity updates actually start, not on a status read. Reading
    /// authorizationStatus() is a static, synchronous, non-prompting call, so
    /// it's safe to exercise for real.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemMotionAuthorizer()

        _ = authorizer.currentAuthorizationStatus()
    }
}
#endif
