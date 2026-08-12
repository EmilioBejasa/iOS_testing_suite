/// One logged call, recorded verbatim - `Equatable` so tests can
/// `XCTAssertEqual` against it directly instead of comparing individual
/// fields.
public struct LoggedEvent: Equatable {
    public let event: String
    public let parameters: [String: String]

    public init(event: String, parameters: [String: String]) {
        self.event = event
        self.parameters = parameters
    }
}

/// Deterministic stand-in for `SystemAnalyticsLogger` - the actually valuable
/// half of this module for app-logic tests: records every logged call so a
/// test can assert "did my code log the right event" instead of needing a
/// real logging backend.
public final class MockAnalyticsLogger: AnalyticsLogging {
    public private(set) var loggedEvents: [LoggedEvent] = []

    public init() {}

    public func log(event: String, parameters: [String: String]) {
        loggedEvents.append(LoggedEvent(event: event, parameters: parameters))
    }
}
