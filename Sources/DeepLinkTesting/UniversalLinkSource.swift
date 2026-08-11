import Foundation

/// A second real-world trigger for the same technique `DeepLinkSource` already
/// uses - a UI test passes the URL as a launch argument instead of driving a
/// real Universal Link, which would need Associated Domains configured and
/// still wouldn't cover `.onContinueUserActivity`'s delivery path any more
/// reliably than a launch argument does.
public enum UniversalLinkSource {
    /// Looks for `--universal-link <url>` in launch arguments.
    public static func url(from arguments: [String] = ProcessInfo.processInfo.arguments) -> URL? {
        guard let index = arguments.firstIndex(of: "--universal-link"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(string: arguments[index + 1])
    }
}
