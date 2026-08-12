/// Lets app code ask "wait this long" without calling `Task.sleep` directly,
/// so tests can skip the wait instead of racing real wall-clock time - the
/// async counterpart to `TimeControl`'s `DateProviding` for code that delays
/// itself (retry backoff, debounce, polling loops) rather than just reading
/// the current time.
public protocol AsyncSleeping {
    func sleep(for duration: Duration) async throws
}
