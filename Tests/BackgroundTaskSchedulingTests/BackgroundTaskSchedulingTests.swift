#if canImport(BackgroundTasks)
import XCTest
import BackgroundTasks
import BackgroundTaskScheduling

/// Mock-only, unlike every other module's kit-level tests in this repo, which
/// all exercise at least a safe subset of the real implementation. There isn't
/// a safe subset here: unlike a system dialog (avoidable) or an unresolved
/// continuation (harmless if never awaited), BGTaskScheduler.register()/submit()
/// have real, documented crash reports tied to registration timing and to
/// identifiers missing from Info.plist's BGTaskSchedulerPermittedIdentifiers -
/// exactly the kind of non-standard invocation context a plain XCTest run is.
/// SystemBackgroundTaskScheduler is still built and shipped; it's just never
/// called here.
final class BackgroundTaskSchedulingTests: XCTestCase {
    func testRegisterRecordsIdentifierAndReturnsConfiguredResult() {
        let scheduler = MockBackgroundTaskScheduler()
        scheduler.registerResult = false

        let result = scheduler.register(forTaskWithIdentifier: "com.quotebox.qa.refresh") { _ in }

        XCTAssertEqual(scheduler.registeredIdentifiers, ["com.quotebox.qa.refresh"])
        XCTAssertFalse(result)
    }

    func testSubmitRecordsRequest() throws {
        let scheduler = MockBackgroundTaskScheduler()
        let request = BGAppRefreshTaskRequest(identifier: "com.quotebox.qa.refresh")

        try scheduler.submit(request)

        XCTAssertEqual(scheduler.submittedRequests.count, 1)
        XCTAssertEqual(scheduler.submittedRequests.first?.identifier, "com.quotebox.qa.refresh")
    }

    func testSubmitThrowsConfiguredError() {
        let scheduler = MockBackgroundTaskScheduler()
        scheduler.submitError = CocoaError(.featureUnsupported)
        let request = BGAppRefreshTaskRequest(identifier: "com.quotebox.qa.refresh")

        XCTAssertThrowsError(try scheduler.submit(request))
        XCTAssertTrue(scheduler.submittedRequests.isEmpty)
    }

    func testCancelRecordsIdentifier() {
        let scheduler = MockBackgroundTaskScheduler()

        scheduler.cancel(taskRequestWithIdentifier: "com.quotebox.qa.refresh")

        XCTAssertEqual(scheduler.cancelledIdentifiers, ["com.quotebox.qa.refresh"])
    }
}
#endif
