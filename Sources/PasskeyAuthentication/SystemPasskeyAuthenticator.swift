#if os(iOS)
import AuthenticationServices
import Foundation
import UIKit

/// Wraps `ASAuthorizationPlatformPublicKeyCredentialProvider`/
/// `ASAuthorizationController`, the same delegate-to-`async` bridging
/// technique `SystemAppleSignInProvider` already established for
/// `ASAuthorizationControllerDelegate`. `@available(iOS 15.0, *)` since
/// `ASAuthorizationPlatformPublicKeyCredentialProvider` itself is - newer
/// than the package's iOS 13 floor (`Package.swift`), same class of
/// annotation `BluetoothAuthorization` needed for `CBManagerAuthorization`.
/// Both `requestRegistration`/`requestAssertion` always show the real
/// system passkey sheet - there's no non-prompting half here the way
/// `credentialState(for:)` gives `AppleSignIn`.
@available(iOS 15.0, *)
public final class SystemPasskeyAuthenticator: NSObject, PasskeyAuthenticating {
    private let relyingPartyIdentifier: String
    private var registrationContinuation: CheckedContinuation<PasskeyRegistration, Error>?
    private var assertionContinuation: CheckedContinuation<PasskeyAssertion, Error>?

    public init(relyingPartyIdentifier: String) {
        self.relyingPartyIdentifier = relyingPartyIdentifier
        super.init()
    }

    public func requestRegistration(challenge: Data, userName: String, userID: Data) async throws -> PasskeyRegistration {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyIdentifier)
        let request = provider.createCredentialRegistrationRequest(challenge: challenge, name: userName, userID: userID)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { continuation in
            self.registrationContinuation = continuation
            controller.performRequests()
        }
    }

    public func requestAssertion(challenge: Data) async throws -> PasskeyAssertion {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyIdentifier)
        let request = provider.createCredentialAssertionRequest(challenge: challenge)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { continuation in
            self.assertionContinuation = continuation
            controller.performRequests()
        }
    }
}

@available(iOS 15.0, *)
extension SystemPasskeyAuthenticator: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let registration = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            registrationContinuation?.resume(returning: PasskeyRegistration(
                credentialID: registration.credentialID,
                rawAttestationObject: registration.rawAttestationObject,
                rawClientDataJSON: registration.rawClientDataJSON
            ))
            registrationContinuation = nil
            return
        }

        if let assertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            assertionContinuation?.resume(returning: PasskeyAssertion(
                credentialID: assertion.credentialID,
                rawAuthenticatorData: assertion.rawAuthenticatorData,
                signature: assertion.signature,
                userID: assertion.userID,
                rawClientDataJSON: assertion.rawClientDataJSON
            ))
            assertionContinuation = nil
            return
        }

        let error = CocoaError(.featureUnsupported)
        registrationContinuation?.resume(throwing: error)
        registrationContinuation = nil
        assertionContinuation?.resume(throwing: error)
        assertionContinuation = nil
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        registrationContinuation?.resume(throwing: error)
        registrationContinuation = nil
        assertionContinuation?.resume(throwing: error)
        assertionContinuation = nil
    }
}

@available(iOS 15.0, *)
extension SystemPasskeyAuthenticator: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return keyWindow ?? ASPresentationAnchor()
    }
}
#endif
