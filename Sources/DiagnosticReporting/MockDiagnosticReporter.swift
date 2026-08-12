/// Deterministic stand-in for `SystemDiagnosticReporter` - records whether
/// reporting was started rather than faking real payloads, the same "records
/// what a call site asked for" shape `MockBackgroundTaskScheduler` uses.
public final class MockDiagnosticReporter: DiagnosticReporting {
    public private(set) var isReporting = false
    public private(set) var startReportingCallCount = 0
    public private(set) var stopReportingCallCount = 0

    public init() {}

    public func startReporting() {
        isReporting = true
        startReportingCallCount += 1
    }

    public func stopReporting() {
        isReporting = false
        stopReportingCallCount += 1
    }
}
