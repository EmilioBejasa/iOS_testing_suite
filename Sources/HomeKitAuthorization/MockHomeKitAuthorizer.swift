#if os(iOS)
import HomeKit

/// Deterministic stand-in for `SystemHomeKitAuthorizer` - safe to exercise
/// in any test, since it never touches the real home manager. Defaults to
/// `[]` (the empty `OptionSet`), not a named case - `HMHomeManagerAuthorizationStatus`
/// has no `.notDetermined` member.
public final class MockHomeKitAuthorizer: HomeKitAuthorizing {
    public var status: HMHomeManagerAuthorizationStatus

    public init(status: HMHomeManagerAuthorizationStatus = []) {
        self.status = status
    }

    public func currentAuthorizationStatus() -> HMHomeManagerAuthorizationStatus {
        status
    }
}
#endif
