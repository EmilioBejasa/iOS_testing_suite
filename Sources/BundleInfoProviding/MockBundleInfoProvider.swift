/// Deterministic stand-in for `SystemBundleInfoProvider` - safe to exercise
/// in any test, since it never reads a real bundle's Info.plist.
public final class MockBundleInfoProvider: BundleInfoProviding {
    public var appVersion: String
    public var buildNumber: String

    public init(appVersion: String = "1.0", buildNumber: String = "1") {
        self.appVersion = appVersion
        self.buildNumber = buildNumber
    }
}
