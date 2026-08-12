/// Wraps `MetricKit`, a system framework with a completely different shape
/// from every authorization module above: there's no permission prompt and
/// no status enum at all - `MXMetricManager.shared.add(subscriber:)`/
/// `.remove(subscriber:)` is pure opt-in subscription, so this protocol just
/// exposes start/stop rather than a status read.
public protocol DiagnosticReporting {
    func startReporting()
    func stopReporting()
}
