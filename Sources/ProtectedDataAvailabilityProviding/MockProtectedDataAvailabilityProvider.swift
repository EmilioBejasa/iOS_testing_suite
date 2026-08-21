#if canImport(UIKit)
/// Deterministic stand-in for `SystemProtectedDataAvailabilityProvider` -
/// safe to exercise in any test, since it never touches the real
/// application's data-protection state.
public final class MockProtectedDataAvailabilityProvider: ProtectedDataAvailabilityProviding {
    public private(set) var isProtectedDataAvailable: Bool
    private var onChange: ((Bool) -> Void)?

    public init(isProtectedDataAvailable: Bool = true) {
        self.isProtectedDataAvailable = isProtectedDataAvailable
    }

    public func startMonitoringProtectedDataAvailability(onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
        onChange(isProtectedDataAvailable)
    }

    public func stopMonitoringProtectedDataAvailability() {
        onChange = nil
    }

    /// Drives `onChange` manually, simulating the device locking/unlocking
    /// a test wants to react to.
    public func simulateProtectedDataAvailabilityChange(to available: Bool) {
        isProtectedDataAvailable = available
        onChange?(available)
    }
}
#endif
