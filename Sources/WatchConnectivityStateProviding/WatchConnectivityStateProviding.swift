/// No permission concept at all, unlike every authorization module in this
/// kit - `WatchConnectivity` never prompts. Lets app code ask "is a Watch
/// paired/does it have our app?" through an injectable dependency instead of
/// touching `WCSession` directly.
public protocol WatchConnectivityStateProviding {
    func isSupported() -> Bool
    func isPaired() -> Bool
    func isWatchAppInstalled() -> Bool
}
