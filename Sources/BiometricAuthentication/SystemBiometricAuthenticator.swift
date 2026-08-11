import LocalAuthentication

/// Wraps `LAContext`. `evaluatePolicy` is completion-handler based, bridged to
/// `async` here via `CheckedContinuation` — simpler than
/// `SystemLocationAuthorizer`'s bridge since there's a completion closure to
/// resume from directly, with no delegate subclass required.
public final class SystemBiometricAuthenticator: BiometricAuthenticating {
    public init() {}

    public func canEvaluate() -> Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    public func evaluate(reason: String) async -> Bool {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return false
        }
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
