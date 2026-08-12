import Foundation

/// Wraps raw `UserDefaults` directly rather than depending on this kit's own
/// `UserDefaultsStore` target - every module in this kit stays independent
/// (see `DebugOverlay`'s README note on staying dependency-free), so this
/// doesn't introduce the kit's first intra-module dependency. Reads a bool
/// for `"featureFlag.<name>"`, defaulting `false` when absent - a local
/// override a developer/QA build can flip via a launch argument or Settings
/// bundle, not a fetched remote value.
public final class SystemFeatureFlags: FeatureFlagging {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func isEnabled(_ flag: String) -> Bool {
        defaults.bool(forKey: "featureFlag.\(flag)")
    }
}
