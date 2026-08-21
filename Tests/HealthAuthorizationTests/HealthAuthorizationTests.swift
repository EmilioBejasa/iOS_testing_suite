#if canImport(HealthKit)
import XCTest
import HealthKit
import HealthAuthorization

final class HealthAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockHealthAuthorizer(status: .sharingAuthorized)
        let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount)!

        XCTAssertEqual(authorizer.currentAuthorizationStatus(for: stepCount), .sharingAuthorized)

        let granted = await authorizer.requestAuthorization(toShare: [], read: [stepCount])
        XCTAssertTrue(granted)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockHealthAuthorizer()
        let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount)!

        XCTAssertEqual(authorizer.currentAuthorizationStatus(for: stepCount), .notDetermined)
    }

    /// Unlike every other authorization module's real-side test, this doesn't
    /// even call the normally-safe status read. HealthKit needs the
    /// com.apple.developer.healthkit entitlement (QuoteBox doesn't have it),
    /// and HealthKit is unavailable on iPad entirely
    /// (HKHealthStore.isHealthDataAvailable() is always false there) - this
    /// repo's own CI device matrix includes an iPad. Same "documented risk,
    /// untested real path" treatment CloudKitAccountCheckingTests gives
    /// CKContainer.accountStatus(): only construct the type, never call a
    /// method on it.
    func testSystemAuthorizerConstructsWithoutCrashing() {
        _ = SystemHealthAuthorizer()
    }
}
#endif
