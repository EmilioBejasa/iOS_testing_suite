import Contacts

/// A fourth permission-gated system service, following `LocationAuthorization`'s
/// and `PhotoLibraryAuthorization`'s protocol+real+fake shape. Uses
/// `CNAuthorizationStatus` directly rather than reinventing a simplified enum —
/// same reasoning `LocationAuthorization` gives for keeping `CLAuthorizationStatus`.
public protocol ContactsAuthorizing {
    func currentAuthorizationStatus() -> CNAuthorizationStatus
    func requestAccess() async -> Bool
}
