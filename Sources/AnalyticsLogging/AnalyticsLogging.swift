/// Lets app code report an analytics event through an injectable dependency
/// instead of calling a hardcoded analytics SDK directly, so a test can
/// assert on what was logged instead of needing a real analytics backend.
/// Deliberately scoped like `FeatureFlagging`: there's no single Apple
/// framework for custom event analytics the way there is for, say, location
/// or contacts - `SystemAnalyticsLogger` wraps `OSLog`'s `Logger` as the
/// closest first-party fit, not a specific vendor SDK.
public protocol AnalyticsLogging {
    func log(event: String, parameters: [String: String])
}
