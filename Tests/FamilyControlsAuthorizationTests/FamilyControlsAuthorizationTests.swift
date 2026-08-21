#if canImport(FamilyControls)
import XCTest
import FamilyControls
import FamilyControlsAuthorization

final class FamilyControlsAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockFamilyControlsAuthorizer(status: .approved)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .approved)

        let granted = await authorizer.requestAuthorization()
        XCTAssertTrue(granted)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockFamilyControlsAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Family Controls requires the privileged com.apple.developer.family-controls
    /// entitlement (Apple approval required to ship) - QuoteBox doesn't have
    /// it. Same "documented risk, untested real path" treatment
    /// HealthAuthorizationTests/CloudKitAccountCheckingTests give: only
    /// construct the type, never call a method on it. Genuinely uncertain
    /// whether even the status read would be crash-safe without the
    /// entitlement (unlike Siri/Focus Status, requestAuthorization here is
    /// async throws rather than a hard-crashing call, so the failure mode
    /// might differ) - defaulting to the conservative option rather than
    /// guessing.
    func testSystemAuthorizerConstructsWithoutCrashing() {
        _ = SystemFamilyControlsAuthorizer()
    }
}
#endif
