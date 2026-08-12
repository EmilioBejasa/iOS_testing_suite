/// Lets app code ask "wait this long" without calling `Task.sleep` directly,
/// so tests can skip the wait instead of racing real wall-clock time - the
/// async counterpart to `TimeControl`'s `DateProviding` for code that delays
/// itself (retry backoff, debounce, polling loops) rather than just reading
/// the current time.
///
/// `Duration` itself is `@available(iOS 16, *)` in Apple's headers, so merely
/// naming it here requires this annotation too - same reasoning
/// `TrackingAuthorizing` gives for `ATTrackingManager.AuthorizationStatus`:
/// the package compiles against its own iOS 13 floor (`Package.swift`),
/// independent of whatever deployment target a consuming app sets.
@available(iOS 16.0, *)
public protocol AsyncSleeping {
    func sleep(for duration: Duration) async throws
}
