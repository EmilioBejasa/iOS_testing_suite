import UIKit

/// Wraps `UIImpactFeedbackGenerator(style:).impactOccurred()`, bridged
/// through `await MainActor.run { ... }` the same way
/// `SystemReviewRequester` bridges `UIApplication.shared` work.
public final class SystemHapticFeedbackProvider: HapticFeedbackProviding {
    public init() {}

    public func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) async {
        await MainActor.run {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
}
