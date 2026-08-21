#if canImport(UIKit)
import XCTest
import AuthenticationServices
import AppleSignIn

final class AppleSignInTests: XCTestCase {
    func testMockReturnsConfiguredCredentialState() async {
        let provider = MockAppleSignInProvider(credentialStateResult: .authorized)

        let state = await provider.credentialState(for: "any.user")

        XCTAssertEqual(state, .authorized)
    }

    func testMockSignInReturnsConfiguredCredential() async throws {
        let credential = AppleIDCredential(userIdentifier: "mock.user", email: "mock@example.com")
        let provider = MockAppleSignInProvider(signInResult: .success(credential))

        let result = try await provider.requestSignIn()

        XCTAssertEqual(result, credential)
    }

    func testMockSignInThrowsConfiguredError() async {
        let provider = MockAppleSignInProvider(signInResult: .failure(CocoaError(.userCancelled)))

        do {
            _ = try await provider.requestSignIn()
            XCTFail("Expected requestSignIn() to throw")
        } catch {
            // Any thrown error satisfies this - the point is that it throws.
        }
    }

    /// Exercised against the real provider since it's safe: getCredentialState(for:)
    /// never shows a system dialog, and resolves quickly with .notFound for a
    /// user ID nothing has ever signed in with. requestSignIn() is never called
    /// against the real provider here - it always shows the actual system
    /// sign-in sheet, which XCTest can't dismiss headlessly.
    func testSystemProviderReadsCredentialStateWithoutPrompting() async {
        let provider = SystemAppleSignInProvider()

        let state = await provider.credentialState(for: "com.quotebox.qa.tests.unused-user-id")

        XCTAssertEqual(state, .notFound)
    }
}
#endif
