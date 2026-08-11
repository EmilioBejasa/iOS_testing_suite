import XCTest
import CloudKit
import CloudKitAccountChecking

/// Mock-only, same category `BackgroundTaskSchedulingTests.swift` already
/// established: `SystemCloudKitAccountChecker` is never called here, real or
/// otherwise. Calling `CKContainer.default().accountStatus()` without the
/// `com.apple.developer.icloud-services` entitlement (which `QuoteBox` doesn't
/// have) can crash with an uncatchable `CKException` rather than throwing a
/// normal Swift error - confirmed via Apple Developer Forums reports before
/// building this. Unlike a system dialog (avoidable) or an unresolved
/// continuation (harmless if never awaited), there's credible crash risk here,
/// so `SystemCloudKitAccountChecker` is built and shipped but not exercised.
final class CloudKitAccountCheckingTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let checker = MockCloudKitAccountChecker(status: .available)

        let status = await checker.accountStatus()

        XCTAssertEqual(status, .available)
    }

    func testMockDefaultsToAvailable() async {
        let checker = MockCloudKitAccountChecker()

        let status = await checker.accountStatus()

        XCTAssertEqual(status, .available)
    }

    func testMockCanReportUnavailableStatuses() async {
        let checker = MockCloudKitAccountChecker(status: .noAccount)

        let status = await checker.accountStatus()

        XCTAssertEqual(status, .noAccount)
    }
}
