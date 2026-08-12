/// Lets app code ask "what version/build is this?" through an injectable
/// dependency instead of reading `Bundle.main.infoDictionary` directly, so a
/// test can force a specific version string (for a "what's new" screen, a
/// support-email footer, etc.) deterministically.
public protocol BundleInfoProviding {
    var appVersion: String { get }
    var buildNumber: String { get }
}
