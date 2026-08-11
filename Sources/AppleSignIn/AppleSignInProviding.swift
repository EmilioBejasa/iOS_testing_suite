import AuthenticationServices
import Foundation

/// Unlike `ASAuthorizationAppleIDCredential` (a class with no public initializer -
/// the same constraint `PurchaseSupport` documents for StoreKit's `Product`),
/// this is a plain struct so `MockAppleSignInProvider` can construct one without
/// a real sign-in flow. `ASAuthorizationAppleIDProvider.CredentialState` doesn't
/// have this problem (a plain enum, its cases are directly constructible), so it's
/// kept as Apple's own type below - same reasoning `LocationAuthorization` gives
/// for keeping `CLAuthorizationStatus` as-is.
public struct AppleIDCredential: Equatable {
    public let userIdentifier: String
    public let email: String?
    public let fullName: PersonNameComponents?

    public init(userIdentifier: String, email: String? = nil, fullName: PersonNameComponents? = nil) {
        self.userIdentifier = userIdentifier
        self.email = email
        self.fullName = fullName
    }
}

public protocol AppleSignInProviding {
    func credentialState(for userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState
    func requestSignIn() async throws -> AppleIDCredential
}
