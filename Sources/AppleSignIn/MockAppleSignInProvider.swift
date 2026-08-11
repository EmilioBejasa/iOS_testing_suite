import AuthenticationServices

/// Deterministic stand-in for `SystemAppleSignInProvider` - safe to exercise in
/// any test, since it never touches `AuthenticationServices` or shows the real
/// system sign-in sheet.
public final class MockAppleSignInProvider: AppleSignInProviding {
    public enum SignInResult {
        case success(AppleIDCredential)
        case failure(Error)
    }

    public var credentialStateResult: ASAuthorizationAppleIDProvider.CredentialState
    public var signInResult: SignInResult

    public init(
        credentialStateResult: ASAuthorizationAppleIDProvider.CredentialState = .notFound,
        signInResult: SignInResult = .success(AppleIDCredential(userIdentifier: "mock.user"))
    ) {
        self.credentialStateResult = credentialStateResult
        self.signInResult = signInResult
    }

    public func credentialState(for userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        credentialStateResult
    }

    public func requestSignIn() async throws -> AppleIDCredential {
        switch signInResult {
        case .success(let credential):
            return credential
        case .failure(let error):
            throw error
        }
    }
}
