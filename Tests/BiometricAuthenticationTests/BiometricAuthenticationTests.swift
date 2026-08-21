import XCTest
import BiometricAuthentication

final class BiometricAuthenticationTests: XCTestCase {
    func testMockReturnsConfiguredResults() async {
        let authenticator = MockBiometricAuthenticator(canEvaluateResult: true, evaluateResult: true)

        XCTAssertTrue(authenticator.canEvaluate())
        let result = await authenticator.evaluate(reason: "Unlock QuoteBox")
        XCTAssertTrue(result)
    }

    func testMockCanReportUnavailableOrDeniedResults() async {
        let authenticator = MockBiometricAuthenticator(canEvaluateResult: false, evaluateResult: false)

        XCTAssertFalse(authenticator.canEvaluate())
        let result = await authenticator.evaluate(reason: "Unlock QuoteBox")
        XCTAssertFalse(result)
    }

    /// Deliberately only calls canEvaluate() - never evaluate() against the real
    /// authenticator. evaluate() always triggers the real Face ID/Touch ID system
    /// prompt, which XCTest can't dismiss headlessly and would hang the run rather
    /// than just fail it. canEvaluate() is a synchronous capability check that
    /// never prompts, so it's safe here.
    func testSystemAuthenticatorChecksCapabilityWithoutPrompting() {
        let authenticator = SystemBiometricAuthenticator()

        // A CI Simulator has no biometrics enrolled by default; the only thing
        // this assertion proves is that the capability check doesn't crash or
        // hang - not any particular result.
        _ = authenticator.canEvaluate()
    }
}
