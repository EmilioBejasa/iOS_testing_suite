/// Deterministic stand-in for `SystemFeatureFlags` - the actually valuable
/// half of this module for app-logic tests: settable per-flag overrides with
/// no `UserDefaults` round trip involved. Unset flags default to `false`,
/// same as `SystemFeatureFlags`.
public final class MockFeatureFlags: FeatureFlagging {
    public var overrides: [String: Bool]

    public init(overrides: [String: Bool] = [:]) {
        self.overrides = overrides
    }

    public func isEnabled(_ flag: String) -> Bool {
        overrides[flag] ?? false
    }
}
