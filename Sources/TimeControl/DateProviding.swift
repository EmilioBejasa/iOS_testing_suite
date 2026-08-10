import Foundation

/// Lets app code ask "what time is it?" without calling `Date()` directly, so tests
/// can control the answer instead of racing real wall-clock time.
public protocol DateProviding {
    func now() -> Date
}

public struct SystemDateProvider: DateProviding {
    public init() {}

    public func now() -> Date { Date() }
}

/// Settable stand-in for tests — advance `currentDate` to simulate time passing
/// without a real sleep.
public final class TestDateProvider: DateProviding {
    public var currentDate: Date

    public init(currentDate: Date = Date()) {
        self.currentDate = currentDate
    }

    public func now() -> Date { currentDate }
}
