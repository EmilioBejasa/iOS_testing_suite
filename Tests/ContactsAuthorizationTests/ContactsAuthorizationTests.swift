import XCTest
import Contacts
import ContactsAuthorization

final class ContactsAuthorizationTests: XCTestCase {
    func testMockReturnsConfiguredStatus() async {
        let authorizer = MockContactsAuthorizer(status: .authorized)

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .authorized)

        let granted = await authorizer.requestAccess()
        XCTAssertTrue(granted)
    }

    func testMockDefaultsToNotDetermined() {
        let authorizer = MockContactsAuthorizer()

        XCTAssertEqual(authorizer.currentAuthorizationStatus(), .notDetermined)
    }

    /// Deliberately only reads status - never calls requestAccess() against the
    /// real authorizer. That triggers an actual system permission alert when
    /// status is .notDetermined, which XCTest can't dismiss headlessly and would
    /// hang the run rather than just fail it. Reading authorizationStatus(for:)
    /// is a static, synchronous property read that never prompts, so it's safe
    /// here.
    func testSystemAuthorizerReadsStatusWithoutPrompting() {
        let authorizer = SystemContactsAuthorizer()

        // A fresh Simulator install starts .notDetermined; the only thing this
        // assertion proves is that reading status doesn't crash or hang - not
        // any particular status value.
        _ = authorizer.currentAuthorizationStatus()
    }
}
