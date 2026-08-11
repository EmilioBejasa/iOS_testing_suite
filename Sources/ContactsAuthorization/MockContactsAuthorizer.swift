import Contacts

/// Deterministic stand-in for `SystemContactsAuthorizer` - safe to exercise in
/// any test, since it never touches the real Contacts framework or shows a
/// system prompt.
public final class MockContactsAuthorizer: ContactsAuthorizing {
    public var status: CNAuthorizationStatus
    public var accessResult: Bool

    public init(status: CNAuthorizationStatus = .notDetermined, accessResult: Bool = true) {
        self.status = status
        self.accessResult = accessResult
    }

    public func currentAuthorizationStatus() -> CNAuthorizationStatus {
        status
    }

    public func requestAccess() async -> Bool {
        accessResult
    }
}
