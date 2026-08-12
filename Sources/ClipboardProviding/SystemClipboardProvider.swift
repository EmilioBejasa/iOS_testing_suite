import UIKit

/// Wraps `UIPasteboard.general.string` (get/set). Deliberately kept
/// synchronous, unlike `AccessibilityStateProviding`/`HapticFeedbackProviding`/
/// `IdleTimerControlling`: `UIPasteboard` is documented by Apple as safe to
/// use off the main thread (designed for cross-process access, unlike most
/// UIKit surface), so it hasn't picked up the same `@MainActor` isolation
/// those other UIKit types have.
public final class SystemClipboardProvider: ClipboardProviding {
    public init() {}

    public func copy(_ string: String) {
        UIPasteboard.general.string = string
    }

    public func currentString() -> String? {
        UIPasteboard.general.string
    }
}
