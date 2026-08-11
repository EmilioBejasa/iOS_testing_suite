/// Face ID/Touch ID doesn't fit the `LocalNotifications`/`LocationAuthorization`
/// shape exactly: there's no persisted "authorization status" to read back later
/// — `LAContext` only offers a synchronous capability check (is biometric auth
/// configured on this device right now) and an evaluation that always prompts.
/// This protocol reflects that directly rather than forcing a fake authorization
/// status enum onto an API that doesn't have one.
public protocol BiometricAuthenticating {
    /// Synchronous, non-prompting capability check — never shows system UI.
    func canEvaluate() -> Bool
    /// Always triggers the real Face ID/Touch ID system prompt on
    /// `SystemBiometricAuthenticator`.
    func evaluate(reason: String) async -> Bool
}
