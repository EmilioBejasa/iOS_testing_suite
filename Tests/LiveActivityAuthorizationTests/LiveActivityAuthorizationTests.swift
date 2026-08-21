#if canImport(ActivityKit)
import XCTest
import ActivityKit
import LiveActivityAuthorization

final class LiveActivityAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredValue() {
        let authorizer = MockLiveActivityAuthorizer(areActivitiesEnabled: true)

        XCTAssertTrue(authorizer.areActivitiesEnabled)
    }

    func testMockDefaultsToFalse() {
        let authorizer = MockLiveActivityAuthorizer()

        XCTAssertFalse(authorizer.areActivitiesEnabled)
    }

    /// Safe to exercise for real - ActivityAuthorizationInfo.areActivitiesEnabled
    /// needs no entitlement and never prompts (confirmed via WebSearch before
    /// writing this module).
    func testSystemAuthorizerReadsWithoutCrashing() {
        let authorizer = SystemLiveActivityAuthorizer()

        _ = authorizer.areActivitiesEnabled
    }
}
#endif
