import XCTest
import Network
import NetworkReachabilityMonitoring

final class NetworkReachabilityMonitoringTests: XCTestCase {
    func testMockStartMonitoringDeliversCurrentStatusImmediately() {
        let monitor = MockNetworkReachabilityMonitor(currentStatus: .satisfied)
        var received: NWPath.Status?

        monitor.startMonitoring { status in received = status }

        XCTAssertEqual(received, .satisfied)
    }

    func testMockSimulateStatusChangeDrivesUpdate() {
        let monitor = MockNetworkReachabilityMonitor(currentStatus: .satisfied)
        var received: [NWPath.Status] = []
        monitor.startMonitoring { status in received.append(status) }

        monitor.simulateStatusChange(to: .unsatisfied)

        XCTAssertEqual(received, [.satisfied, .unsatisfied])
        XCTAssertEqual(monitor.currentStatus, .unsatisfied)
    }

    func testMockStopMonitoringSilencesFurtherUpdates() {
        let monitor = MockNetworkReachabilityMonitor(currentStatus: .satisfied)
        var received: [NWPath.Status] = []
        monitor.startMonitoring { status in received.append(status) }

        monitor.stopMonitoring()
        monitor.simulateStatusChange(to: .unsatisfied)

        XCTAssertEqual(received, [.satisfied])
    }

    /// Deliberately only constructs SystemNetworkReachabilityMonitor - never
    /// starts it. NWPathMonitor.start(queue:) runs indefinitely on a background
    /// queue with no synchronous "did it work" signal to assert on cheaply, so
    /// there's nothing a unit test gains from starting it here.
    func testSystemMonitorConstructsWithoutCrashing() {
        _ = SystemNetworkReachabilityMonitor()
    }
}
