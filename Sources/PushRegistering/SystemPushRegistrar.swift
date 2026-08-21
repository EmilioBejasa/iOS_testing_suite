#if canImport(UIKit)
import UIKit

/// Wraps `UIApplication.registerForRemoteNotifications()`. The result arrives via
/// `UIApplicationDelegate` callbacks, not a completion handler, so a host app must
/// forward `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` and
/// `application(_:didFailToRegisterForRemoteNotificationsWithError:)` into
/// `didRegister(deviceToken:)`/`didFailToRegister(error:)` for the continuation
/// below to ever resume - this class alone can't observe those callbacks itself.
public final class SystemPushRegistrar: NSObject, PushRegistering {
    private var continuation: CheckedContinuation<PushRegistrationOutcome, Never>?

    public override init() {
        super.init()
    }

    public func registerForRemoteNotifications() async -> PushRegistrationOutcome {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    public func didRegister(deviceToken: Data) {
        continuation?.resume(returning: .token(deviceToken))
        continuation = nil
    }

    public func didFailToRegister(error: Error) {
        continuation?.resume(returning: .failed(error.localizedDescription))
        continuation = nil
    }
}
#endif
