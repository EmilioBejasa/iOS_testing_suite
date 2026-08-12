import UIKit

/// Wraps `UIAccessibility.isVoiceOverRunning`/`.isReduceMotionEnabled`,
/// bridged through `await MainActor.run { ... }` the same way
/// `SystemReviewRequester` bridges `UIApplication.shared` work.
public final class SystemAccessibilityStateProvider: AccessibilityStateProviding {
    public init() {}

    public func isVoiceOverRunning() async -> Bool {
        await MainActor.run { UIAccessibility.isVoiceOverRunning }
    }

    public func isReduceMotionEnabled() async -> Bool {
        await MainActor.run { UIAccessibility.isReduceMotionEnabled }
    }
}
