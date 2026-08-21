#if os(iOS)
/// Deterministic stand-in for `SystemScreenCaptureStateProvider` - safe to
/// exercise in any test, since it never touches the real screen.
public final class MockScreenCaptureStateProvider: ScreenCaptureStateProviding {
    public private(set) var isCaptured: Bool
    private var onChange: ((Bool) -> Void)?

    public init(isCaptured: Bool = false) {
        self.isCaptured = isCaptured
    }

    public func isScreenCaptured() async -> Bool {
        isCaptured
    }

    public func startMonitoringScreenCapture(onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
        onChange(isCaptured)
    }

    public func stopMonitoringScreenCapture() {
        onChange = nil
    }

    /// Drives `onChange` manually, simulating the user starting/stopping a
    /// screen recording a test wants to react to - same shape as
    /// `MockPowerStateProvider`'s `simulateThermalStateChange(to:)`.
    public func simulateScreenCaptureChange(to captured: Bool) {
        isCaptured = captured
        onChange?(captured)
    }
}
#endif
