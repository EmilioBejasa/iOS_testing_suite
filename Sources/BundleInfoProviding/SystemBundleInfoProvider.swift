import Foundation

/// Wraps `Bundle.infoDictionary` - a plain, synchronous Foundation read.
/// Defaults to `"unknown"` rather than throwing/crashing when a key is
/// missing (e.g. a test bundle with no `CFBundleShortVersionString`), since
/// this is meant to be safe to construct against any bundle.
public final class SystemBundleInfoProvider: BundleInfoProviding {
    private let bundle: Bundle

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    public var appVersion: String {
        bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    public var buildNumber: String {
        bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }
}
