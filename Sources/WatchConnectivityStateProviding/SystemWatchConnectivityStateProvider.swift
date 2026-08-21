#if os(iOS)
import WatchConnectivity

/// Wraps `WCSession`. `WCSession` is not supported on every device this
/// kit's CI matrix runs against (confirmed via WebSearch before writing
/// this - notably unsupported on iPad), so every access guards with
/// `WCSession.isSupported()` first and never force-touches `.default` on an
/// unsupported device - that's the actual crash risk here, not a permission
/// prompt or missing entitlement the way every other module's caution
/// applies.
public final class SystemWatchConnectivityStateProvider: WatchConnectivityStateProviding {
    public init() {}

    public func isSupported() -> Bool {
        WCSession.isSupported()
    }

    public func isPaired() -> Bool {
        guard WCSession.isSupported() else { return false }
        return WCSession.default.isPaired
    }

    public func isWatchAppInstalled() -> Bool {
        guard WCSession.isSupported() else { return false }
        return WCSession.default.isWatchAppInstalled
    }
}
#endif
