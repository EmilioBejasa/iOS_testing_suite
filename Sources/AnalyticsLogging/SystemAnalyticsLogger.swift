import OSLog

/// Wraps `os.Logger` (`OSLog`'s structured-logging API, iOS 14+). Only this
/// class needs `@available(iOS 14.0, *)` - unlike `BluetoothAuthorization`'s
/// `CBManagerAuthorization`, `Logger` never appears in `AnalyticsLogging`'s
/// own signature, so the gate doesn't need to propagate to the protocol.
@available(iOS 14.0, *)
public final class SystemAnalyticsLogger: AnalyticsLogging {
    private let logger: Logger

    public init(subsystem: String = "AnalyticsLogging", category: String = "events") {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(event: String, parameters: [String: String]) {
        logger.log("\(event, privacy: .public) \(String(describing: parameters), privacy: .public)")
    }
}
