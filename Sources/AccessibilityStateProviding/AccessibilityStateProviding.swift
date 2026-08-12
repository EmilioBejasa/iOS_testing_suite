/// Lets app code ask "is VoiceOver/Reduce Motion on?" through an injectable
/// dependency instead of reading `UIAccessibility` directly, so a test can
/// force either side of an accessibility-aware code path (skip an
/// animation, announce state changes) deterministically. Methods are `async`
/// from the start, not because the underlying reads are slow, but because
/// `UIAccessibility`'s properties are UIKit and recent SDKs increasingly mark
/// UIKit surface `@MainActor` - same reasoning `SystemReviewRequester`
/// already established for `UIApplication.shared` in this repo
/// (`2ac65fa`), applied proactively here rather than discovered via a
/// build failure.
public protocol AccessibilityStateProviding {
    func isVoiceOverRunning() async -> Bool
    func isReduceMotionEnabled() async -> Bool
}
