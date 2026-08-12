/// Deterministic stand-in for `SystemPowerStateProvider` - safe to exercise
/// in any test, since it never touches the real device power state.
public final class MockPowerStateProvider: PowerStateProviding {
    public var isLowPowerModeEnabled: Bool

    public init(isLowPowerModeEnabled: Bool = false) {
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
    }
}
