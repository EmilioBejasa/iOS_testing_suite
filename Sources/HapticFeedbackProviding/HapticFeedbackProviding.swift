#if canImport(UIKit)
import UIKit

/// Lets app code trigger haptic feedback through an injectable dependency
/// instead of constructing `UIImpactFeedbackGenerator` directly, so a test
/// can assert "did my code fire the right haptic" without depending on real
/// hardware (haptics silently no-op on the Simulator). `async` for the same
/// `@MainActor`-proofing reason `AccessibilityStateProviding` gives -
/// `UIFeedbackGenerator` is UIKit.
public protocol HapticFeedbackProviding {
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) async
}
#endif
