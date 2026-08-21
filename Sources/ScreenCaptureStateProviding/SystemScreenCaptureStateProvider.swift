#if os(iOS)
import UIKit

/// Wraps `UIScreen.main.isCaptured`, bridged through `await MainActor.run { ... }`
/// - the exact same technique `SystemAccessibilityStateProvider` already
/// establishes for `UIScreen`'s sibling `@MainActor` UIKit class,
/// `UIAccessibility`. Monitors `UIScreen.capturedDidChangeNotification` via
/// `NotificationCenter` on the main queue, so the callback can read
/// `UIScreen.main.isCaptured` directly without a second `MainActor.run` hop.
public final class SystemScreenCaptureStateProvider: ScreenCaptureStateProviding {
    private var observer: NSObjectProtocol?

    public init() {}

    public func isScreenCaptured() async -> Bool {
        await MainActor.run { UIScreen.main.isCaptured }
    }

    public func startMonitoringScreenCapture(onChange: @escaping (Bool) -> Void) {
        stopMonitoringScreenCapture()
        observer = NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            onChange(UIScreen.main.isCaptured)
        }
    }

    public func stopMonitoringScreenCapture() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
    }

    deinit {
        stopMonitoringScreenCapture()
    }
}
#endif
