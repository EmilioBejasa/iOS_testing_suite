import Network

/// Wraps `NWPathMonitor`, running it on a dedicated background queue (Apple's
/// own requirement — it must not run on the main queue).
public final class SystemNetworkReachabilityMonitor: NetworkReachabilityMonitoring {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.iostestkit.networkreachability")

    public private(set) var currentStatus: NWPath.Status = .requiresConnection

    public init() {}

    public func startMonitoring(onUpdate: @escaping (NWPath.Status) -> Void) {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentStatus = path.status
            onUpdate(path.status)
        }
        monitor.start(queue: queue)
    }

    public func stopMonitoring() {
        monitor.cancel()
    }
}
