/// Lets app code disable/re-enable the screen-lock idle timer through an
/// injectable dependency instead of touching `UIApplication.shared`
/// directly (a video player, a long-running scan flow). `async` for the
/// same reason `AccessibilityStateProviding`/`HapticFeedbackProviding` are -
/// `UIApplication.shared.isIdleTimerDisabled` is exactly the touchpoint
/// `SystemReviewRequester` already had to defer into a `@MainActor` context
/// for in this repo (`2ac65fa`), applied here from the start.
public protocol IdleTimerControlling {
    func setIdleTimerDisabled(_ disabled: Bool) async
    func isIdleTimerDisabled() async -> Bool
}
