/// Deterministic stand-in for `SystemSleeper` - records requested durations
/// and returns immediately instead of actually waiting, so tests exercising
/// retry/backoff/debounce logic run at full speed rather than racing real
/// wall-clock time, same motivation `TestDateProvider` gives for `TimeControl`.
@available(iOS 16.0, *)
public final class MockSleeper: AsyncSleeping {
    public private(set) var requestedDurations: [Duration] = []

    public init() {}

    public func sleep(for duration: Duration) async throws {
        requestedDurations.append(duration)
    }
}
