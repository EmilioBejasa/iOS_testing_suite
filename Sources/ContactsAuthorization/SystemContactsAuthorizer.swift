import Contacts

/// Wraps `CNContactStore`. `requestAccess(for:completionHandler:)` is already a
/// plain completion handler (not a delegate), so it bridges to `async` directly
/// via `CheckedContinuation` - no `NSObject`/delegate subclass needed, unlike
/// `SystemLocationAuthorizer`'s delegate-based bridge.
public final class SystemContactsAuthorizer: ContactsAuthorizing {
    private let store = CNContactStore()

    public init() {}

    public func currentAuthorizationStatus() -> CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    public func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}
