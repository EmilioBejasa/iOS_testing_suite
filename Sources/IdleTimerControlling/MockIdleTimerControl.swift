/// Deterministic stand-in for `SystemIdleTimerControl` - safe to exercise in
/// any test, since it never touches the real application's idle timer.
public final class MockIdleTimerControl: IdleTimerControlling {
    public private(set) var isDisabled = false

    public init() {}

    public func setIdleTimerDisabled(_ disabled: Bool) async {
        isDisabled = disabled
    }

    public func isIdleTimerDisabled() async -> Bool {
        isDisabled
    }
}
