#if os(iOS)
import XCTest
import PasskeyAuthentication

@available(iOS 15.0, *)
final class PasskeyAuthenticationTests: XCTestCase {
    func testMockReturnsConfiguredRegistration() async throws {
        let registration = PasskeyRegistration(credentialID: Data([1, 2, 3]), rawAttestationObject: Data([4, 5]), rawClientDataJSON: Data([6]))
        let authenticator = MockPasskeyAuthenticator(registrationResult: .success(registration))

        let result = try await authenticator.requestRegistration(challenge: Data(), userName: "test", userID: Data())

        XCTAssertEqual(result, registration)
    }

    func testMockReturnsConfiguredAssertion() async throws {
        let assertion = PasskeyAssertion(credentialID: Data([1]), rawAuthenticatorData: Data([2]), signature: Data([3]), userID: Data([4]), rawClientDataJSON: Data([5]))
        let authenticator = MockPasskeyAuthenticator(assertionResult: .success(assertion))

        let result = try await authenticator.requestAssertion(challenge: Data())

        XCTAssertEqual(result, assertion)
    }

    func testMockThrowsConfiguredRegistrationError() async {
        let authenticator = MockPasskeyAuthenticator(registrationResult: .failure(CocoaError(.userCancelled)))

        do {
            _ = try await authenticator.requestRegistration(challenge: Data(), userName: "test", userID: Data())
            XCTFail("Expected requestRegistration() to throw")
        } catch {
            // Any thrown error satisfies this - the point is that it throws.
        }
    }

    func testMockThrowsConfiguredAssertionError() async {
        let authenticator = MockPasskeyAuthenticator(assertionResult: .failure(CocoaError(.userCancelled)))

        do {
            _ = try await authenticator.requestAssertion(challenge: Data())
            XCTFail("Expected requestAssertion() to throw")
        } catch {
            // Any thrown error satisfies this - the point is that it throws.
        }
    }

    /// Safe to construct for real - relyingPartyIdentifier is just stored,
    /// no AuthenticationServices call happens until requestRegistration/
    /// requestAssertion, and both always show the real system passkey sheet
    /// (no non-prompting status read exists here the way AppleSignIn's
    /// credentialState(for:) gives it), so neither is called against the
    /// real authenticator here.
    func testSystemAuthenticatorConstructsWithoutCrashing() {
        _ = SystemPasskeyAuthenticator(relyingPartyIdentifier: "example.com")
    }
}
#endif
