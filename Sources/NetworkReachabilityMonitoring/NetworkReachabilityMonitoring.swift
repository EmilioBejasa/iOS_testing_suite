import Network

/// Distinct from `NetworkStub` — that intercepts individual request/response
/// pairs on a `URLSession`; this reports the device's actual connectivity state.
/// Keeps `NWPath.Status` directly (`.satisfied`/`.unsatisfied`/
/// `.requiresConnection`) rather than reinventing an enum, same reasoning every
/// permission module gives for keeping a framework's own type.
public protocol NetworkReachabilityMonitoring {
    var currentStatus: NWPath.Status { get }
    func startMonitoring(onUpdate: @escaping (NWPath.Status) -> Void)
    func stopMonitoring()
}
