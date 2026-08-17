import Foundation

/// Distinct from `AppleSignIn`: that wraps Sign in with Apple
/// (`ASAuthorizationAppleIDProvider`), a single-vendor identity; this wraps
/// passkeys (`ASAuthorizationPlatformPublicKeyCredentialProvider`), the
/// standards-based WebAuthn/FIDO2 credential every platform is converging on
/// as a passwordless replacement for passwords. Scoped to registration
/// (creating a new passkey) and assertion (signing in with an existing one)
/// - the two operations a relying-party server actually needs, not a full
/// WebAuthn client. Returns plain structs rather than Apple's own
/// `ASAuthorizationPlatformPublicKeyCredentialRegistration`/`...Assertion` -
/// those are classes with no public initializer (the same constraint
/// `PurchaseSupport` documents for StoreKit's `Product`, and `AppleSignIn`
/// already documents for `ASAuthorizationAppleIDCredential`), so
/// `MockPasskeyAuthenticator` couldn't construct one to return. Neither this
/// protocol nor `MockPasskeyAuthenticator` names an `AuthenticationServices`
/// passkey type directly, so unlike `BluetoothAuthorization`/
/// `CalendarAuthorization` neither needs an `@available` annotation - only
/// `SystemPasskeyAuthenticator`, which constructs
/// `ASAuthorizationPlatformPublicKeyCredentialProvider` directly
/// (`@available(iOS 15.0, *)`, newer than the package's iOS 13 floor), does.
public protocol PasskeyAuthenticating {
    func requestRegistration(challenge: Data, userName: String, userID: Data) async throws -> PasskeyRegistration
    func requestAssertion(challenge: Data) async throws -> PasskeyAssertion
}

/// Mirrors `ASAuthorizationPlatformPublicKeyCredentialRegistration`'s three
/// properties (`credentialID`, `rawAttestationObject`, `rawClientDataJSON` -
/// the last two inherited from its
/// `ASAuthorizationPublicKeyCredentialRegistration`/`ASPublicKeyCredential`
/// protocol conformances) as a plain, constructible struct.
public struct PasskeyRegistration: Equatable {
    public let credentialID: Data
    public let rawAttestationObject: Data?
    public let rawClientDataJSON: Data

    public init(credentialID: Data, rawAttestationObject: Data?, rawClientDataJSON: Data) {
        self.credentialID = credentialID
        self.rawAttestationObject = rawAttestationObject
        self.rawClientDataJSON = rawClientDataJSON
    }
}

/// Mirrors `ASAuthorizationPlatformPublicKeyCredentialAssertion`'s
/// properties the same way - `credentialID`/`rawClientDataJSON` from
/// `ASPublicKeyCredential`, `signature`/`userID`/`rawAuthenticatorData` from
/// `ASAuthorizationPublicKeyCredentialAssertion`.
public struct PasskeyAssertion: Equatable {
    public let credentialID: Data
    public let rawAuthenticatorData: Data
    public let signature: Data
    public let userID: Data
    public let rawClientDataJSON: Data

    public init(credentialID: Data, rawAuthenticatorData: Data, signature: Data, userID: Data, rawClientDataJSON: Data) {
        self.credentialID = credentialID
        self.rawAuthenticatorData = rawAuthenticatorData
        self.signature = signature
        self.userID = userID
        self.rawClientDataJSON = rawClientDataJSON
    }
}
