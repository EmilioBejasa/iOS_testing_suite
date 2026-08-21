#if canImport(UIKit)
import XCTest
import PushRegistering

final class PushRegisteringTests: XCTestCase {
    func testMockReturnsConfiguredToken() async {
        let token = Data([0xAA, 0xBB])
        let registrar = MockPushRegistrar(outcome: .token(token))

        let outcome = await registrar.registerForRemoteNotifications()

        XCTAssertEqual(outcome, .token(token))
    }

    func testMockReturnsConfiguredFailure() async {
        let registrar = MockPushRegistrar(outcome: .failed("no connection"))

        let outcome = await registrar.registerForRemoteNotifications()

        XCTAssertEqual(outcome, .failed("no connection"))
    }

    /// Deliberately only constructs SystemPushRegistrar - never calls
    /// registerForRemoteNotifications() against it. registerForRemoteNotifications()
    /// itself never shows a system dialog, but resolving its continuation depends
    /// on a UIApplicationDelegate forwarding didRegister(deviceToken:)/
    /// didFailToRegister(error:) into it, and QuoteBox has no natural need for
    /// push, so it doesn't add that plumbing. Awaiting it here would hang forever
    /// waiting on a continuation nothing resumes.
    func testSystemRegistrarConstructsWithoutCrashing() {
        _ = SystemPushRegistrar()
    }
}
#endif
