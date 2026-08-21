import Foundation

/// Deterministic stand-in for `SystemPasskeyAuthenticator` - safe to
/// exercise in any test, since it never touches `AuthenticationServices` or
/// shows the real system passkey sheet.
public final class MockPasskeyAuthenticator: PasskeyAuthenticating {
    public enum RegistrationResult {
        case success(PasskeyRegistration)
        case failure(Error)
    }

    public enum AssertionResult {
        case success(PasskeyAssertion)
        case failure(Error)
    }

    public var registrationResult: RegistrationResult
    public var assertionResult: AssertionResult

    public init(
        registrationResult: RegistrationResult = .success(
            PasskeyRegistration(credentialID: Data([1]), rawAttestationObject: nil, rawClientDataJSON: Data())
        ),
        assertionResult: AssertionResult = .success(
            PasskeyAssertion(
                credentialID: Data([1]),
                rawAuthenticatorData: Data(),
                signature: Data(),
                userID: Data(),
                rawClientDataJSON: Data()
            )
        )
    ) {
        self.registrationResult = registrationResult
        self.assertionResult = assertionResult
    }

    public func requestRegistration(
        challenge: Data,
        userName: String,
        userID: Data
    ) async throws -> PasskeyRegistration {
        switch registrationResult {
        case .success(let registration):
            return registration
        case .failure(let error):
            throw error
        }
    }

    public func requestAssertion(challenge: Data) async throws -> PasskeyAssertion {
        switch assertionResult {
        case .success(let assertion):
            return assertion
        case .failure(let error):
            throw error
        }
    }
}
