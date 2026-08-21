import XCTest
import AnalyticsLogging

final class AnalyticsLoggingTests: XCTestCase {
    func testMockRecordsLoggedEvents() {
        let logger = MockAnalyticsLogger()

        logger.log(event: "quote_favorited", parameters: ["quoteID": "42"])

        XCTAssertEqual(logger.loggedEvents, [LoggedEvent(event: "quote_favorited", parameters: ["quoteID": "42"])])
    }

    func testMockStartsEmpty() {
        let logger = MockAnalyticsLogger()

        XCTAssertTrue(logger.loggedEvents.isEmpty)
    }

    /// Safe to exercise for real - os.Logger calls never prompt or crash, so
    /// unlike the permission-gated modules above there's no reason to avoid
    /// the real implementation here.
    func testSystemAnalyticsLoggerLogsWithoutCrashing() {
        let logger = SystemAnalyticsLogger()

        logger.log(event: "quote_favorited", parameters: ["quoteID": "42"])
    }
}
