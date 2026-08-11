import Foundation

enum QuoteBoxRoute: Equatable {
    case favorites

    init?(url: URL) {
        guard url.scheme == "quotebox", url.host == "favorites" else { return nil }
        self = .favorites
    }
}
