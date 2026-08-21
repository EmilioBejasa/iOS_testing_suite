#if os(iOS)
import UIKit

/// Lets app code ask "is the screen being recorded, mirrored, or AirPlayed
/// right now?" through an injectable dependency instead of reading
/// `UIScreen.main.isCaptured` directly, so a test can force either side of a
/// capture-aware code path (blur sensitive content, pause media playback)
/// deterministically. `UIScreen` is `@MainActor`-isolated, so methods are
/// `async` from the start, the same reasoning
/// `AccessibilityStateProviding`/`IdleTimerControlling` give for their own
/// UIKit touchpoints. Mirrors `PowerStateProviding`'s thermal-state shape
/// too - a read plus `startMonitoring`/`stopMonitoring` - since capture
/// state can change while the app is already running (a user starts screen
/// recording mid-session).
///
/// **Scope note:** `UIScreen.isCaptured` is deprecated in Apple's own
/// headers in favor of `sceneCaptureState` - but that replacement isn't
/// available in the SDK this kit's own CI actually builds against (Xcode
/// 16.4 / iOS 18.5), and its exact API surface isn't findable in Apple's
/// public documentation yet either, the same "can't verify, won't guess"
/// caution `SwiftDataTestSupport`/`PasskeyAuthentication` were built with
/// instead of chasing an unconfirmed signature. `isCaptured` still works
/// (iOS 11+, well under this module's floor) and only emits a compiler
/// deprecation warning, not a build failure - documenting the tradeoff
/// honestly here rather than either silently using a deprecated API or
/// blocking this module on an API this kit can't currently verify.
public protocol ScreenCaptureStateProviding {
    func isScreenCaptured() async -> Bool
    func startMonitoringScreenCapture(onChange: @escaping (Bool) -> Void)
    func stopMonitoringScreenCapture()
}
#endif
