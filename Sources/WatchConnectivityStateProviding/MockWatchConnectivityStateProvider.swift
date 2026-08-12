/// Deterministic stand-in for `SystemWatchConnectivityStateProvider` - safe
/// to exercise in any test, since it never touches the real WatchConnectivity
/// session.
public final class MockWatchConnectivityStateProvider: WatchConnectivityStateProviding {
    public var supported: Bool
    public var paired: Bool
    public var watchAppInstalled: Bool

    public init(supported: Bool = true, paired: Bool = false, watchAppInstalled: Bool = false) {
        self.supported = supported
        self.paired = paired
        self.watchAppInstalled = watchAppInstalled
    }

    public func isSupported() -> Bool {
        supported
    }

    public func isPaired() -> Bool {
        paired
    }

    public func isWatchAppInstalled() -> Bool {
        watchAppInstalled
    }
}
