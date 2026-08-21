import XCTest
import DiagnosticReporting

final class DiagnosticReportingTests: XCTestCase {
    func testMockRecordsStartAndStop() {
        let reporter = MockDiagnosticReporter()

        reporter.startReporting()
        XCTAssertTrue(reporter.isReporting)
        XCTAssertEqual(reporter.startReportingCallCount, 1)

        reporter.stopReporting()
        XCTAssertFalse(reporter.isReporting)
        XCTAssertEqual(reporter.stopReportingCallCount, 1)
    }

    func testMockStartsNotReporting() {
        let reporter = MockDiagnosticReporter()

        XCTAssertFalse(reporter.isReporting)
    }

    /// Unlike every permission-gated module above, MetricKit has no prompt
    /// and no crash risk from a missing entitlement - MXMetricManager's
    /// add(subscriber:)/remove(subscriber:) is pure opt-in subscription. Safe
    /// to exercise the real reporter fully, the same "safe to call for real"
    /// category ReviewRequesting is in.
    func testSystemReporterStartsAndStopsWithoutCrashing() {
        let reporter = SystemDiagnosticReporter()

        reporter.startReporting()
        reporter.stopReporting()
    }
}
