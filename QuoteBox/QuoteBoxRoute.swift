import Foundation

enum QuoteBoxRoute: Equatable {
    case favorites

    init?(url: URL) {
        if url.scheme == "quotebox", url.host == "favorites" {
            self = .favorites
            return
        }
        // Universal Link shape - quotebox.qa is a placeholder domain, never a
        // real Associated Domain; the app only ever sees this path via the
        // --universal-link launch argument in UniversalLinkSource, not a real
        // Universal Link open.
        if url.scheme == "https", url.host == "quotebox.qa", url.path == "/favorites" {
            self = .favorites
            return
        }
        return nil
    }
}
