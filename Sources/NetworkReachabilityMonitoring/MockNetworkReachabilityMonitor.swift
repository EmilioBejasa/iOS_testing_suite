import Network

/// Deterministic stand-in for `SystemNetworkReachabilityMonitor` - safe to
/// exercise in any test, since it never touches the real `Network` framework.
public final class MockNetworkReachabilityMonitor: NetworkReachabilityMonitoring {
    public private(set) var currentStatus: NWPath.Status
    private var onUpdate: ((NWPath.Status) -> Void)?

    public init(currentStatus: NWPath.Status = .satisfied) {
        self.currentStatus = currentStatus
    }

    public func startMonitoring(onUpdate: @escaping (NWPath.Status) -> Void) {
        self.onUpdate = onUpdate
        onUpdate(currentStatus)
    }

    public func stopMonitoring() {
        onUpdate = nil
    }

    /// Drives `onUpdate` manually, simulating a connectivity change a test wants
    /// to react to.
    public func simulateStatusChange(to status: NWPath.Status) {
        currentStatus = status
        onUpdate?(status)
    }
}
