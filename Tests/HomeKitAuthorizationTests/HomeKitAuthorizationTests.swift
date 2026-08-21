import XCTest
import HomeKit
import HomeKitAuthorization

final class HomeKitAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() {
        let authorizer = MockHomeKitAuthorizer(status: .authorized)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorized)
    }

    func testMockDefaultsToEmptySet() {
        let authorizer = MockHomeKitAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), [])
    }

    /// Deliberately never calls currentAuthorizationStatus() against the
    /// real authorizer. HomeKit is documented to crash on first use without
    /// NSHomeKitUsageDescription in Info.plist - QuoteBox has neither that
    /// key nor the com.apple.developer.homekit entitlement. Constructing
    /// SystemHomeKitAuthorizer() alone is safe (it builds HMHomeManager
    /// lazily inside the method, not here), the same "documented risk,
    /// untested real path" treatment HealthAuthorizationTests/
    /// FamilyControlsAuthorizationTests give their real authorizers.
    func testSystemAuthorizerConstructsWithoutCrashing() {
        _ = SystemHomeKitAuthorizer()
    }
}
