/// Deterministic stand-in for `SystemBiometricAuthenticator` — safe to exercise in
/// any test, since it never touches `LocalAuthentication` or shows the real Face
/// ID/Touch ID prompt.
public final class MockBiometricAuthenticator: BiometricAuthenticating {
    public var canEvaluateResult: Bool
    public var evaluateResult: Bool

    public init(canEvaluateResult: Bool = true, evaluateResult: Bool = true) {
        self.canEvaluateResult = canEvaluateResult
        self.evaluateResult = evaluateResult
    }

    public func canEvaluate() -> Bool {
        canEvaluateResult
    }

    public func evaluate(reason: String) async -> Bool {
        evaluateResult
    }
}
