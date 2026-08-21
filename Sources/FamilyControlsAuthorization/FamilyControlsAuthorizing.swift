#if canImport(FamilyControls)
import FamilyControls

/// Wraps Screen Time's `AuthorizationCenter`. Uses `AuthorizationStatus`
/// directly - a top-level type in the `FamilyControls` module, not nested
/// inside `AuthorizationCenter` despite `authorizationStatus` being one of
/// its properties (a real compile failure caught this wrong assumption, not
/// something verified in advance - fixed here). Same reasoning every other
/// module here gives for keeping a framework's own status type. The
/// `FamilyControls` framework is `@available(iOS 16.0, *)`, annotated on the
/// protocol, mock, AND system class from the start. Requires the privileged
/// `com.apple.developer.family-controls` entitlement (confirmed via
/// WebSearch before writing this - Apple approval required to ship, an even
/// stricter tier than `HealthAuthorization`'s entitlement) - treated with
/// `HealthAuthorization`/`CloudKitAccountChecking`'s most conservative test
/// caution as a result.
@available(iOS 16.0, *)
public protocol FamilyControlsAuthorizing {
    func currentAuthorizationStatus() -> AuthorizationStatus
    func requestAuthorization() async -> Bool
}
#endif
