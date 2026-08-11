import Foundation

/// `XCUIDevice.shared.system.open(url:)` — the obvious way to test deep links —
/// triggers a real system "Open in 'MyApp'" confirmation dialog that a
/// synchronous UI-test call can't dismiss, which would hang CI. This sidesteps
/// that entirely: a UI test passes the URL as a launch argument, and the app
/// reads it at startup exactly like it already does for
/// `--mock-success`/`--mock-error`, testing the app's own URL-to-route parsing
/// and resulting UI state without touching the real OS-level open dialog.
public enum DeepLinkSource {
    /// Looks for `--deep-link <url>` in launch arguments.
    public static func url(from arguments: [String] = ProcessInfo.processInfo.arguments) -> URL? {
        guard let index = arguments.firstIndex(of: "--deep-link"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(string: arguments[index + 1])
    }
}
