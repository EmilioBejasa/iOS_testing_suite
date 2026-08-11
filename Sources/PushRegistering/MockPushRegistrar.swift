import Foundation

/// Deterministic stand-in for `SystemPushRegistrar` - safe to exercise in any
/// test, since it never touches `UIApplication` or needs delegate forwarding.
public final class MockPushRegistrar: PushRegistering {
    public var outcome: PushRegistrationOutcome

    public init(outcome: PushRegistrationOutcome = .token(Data([0x01, 0x02, 0x03]))) {
        self.outcome = outcome
    }

    public func registerForRemoteNotifications() async -> PushRegistrationOutcome {
        outcome
    }
}
