#if os(iOS)
import AuthenticationServices
import UIKit

/// Wraps `ASAuthorizationAppleIDProvider`/`ASAuthorizationController`.
/// `credentialState(for:)` wraps a plain completion handler directly as `async` -
/// no delegate needed, and it never prompts. `requestSignIn()` bridges
/// `ASAuthorizationControllerDelegate`'s callbacks to `async` via
/// `CheckedContinuation` (the same technique `SystemLocationAuthorizer` uses for
/// `CLLocationManagerDelegate`) and always shows the real system sign-in sheet.
public final class SystemAppleSignInProvider: NSObject, AppleSignInProviding {
    private var continuation: CheckedContinuation<AppleIDCredential, Error>?

    public override init() {
        super.init()
    }

    public func credentialState(for userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }

    public func requestSignIn() async throws -> AppleIDCredential {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }
}

extension SystemAppleSignInProvider: ASAuthorizationControllerDelegate {
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: CocoaError(.featureUnsupported))
            continuation = nil
            return
        }
        continuation?.resume(returning: AppleIDCredential(
            userIdentifier: credential.user,
            email: credential.email,
            fullName: credential.fullName
        ))
        continuation = nil
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

extension SystemAppleSignInProvider: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return keyWindow ?? ASPresentationAnchor()
    }
}
#endif
