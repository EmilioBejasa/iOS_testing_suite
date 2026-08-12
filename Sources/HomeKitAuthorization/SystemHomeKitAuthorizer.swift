import HomeKit

/// Wraps `HMHomeManager`. Deliberately does **not** hold `HMHomeManager` as
/// an eager stored property the way `SystemHealthAuthorizer`/
/// `SystemCalendarAuthorizer` hold `HKHealthStore`/`EKEventStore` - HomeKit
/// is documented to crash on first *use* without `NSHomeKitUsageDescription`
/// in `Info.plist`, and merely constructing `HMHomeManager` may itself count
/// as that first use. Constructing it lazily inside the method body instead
/// means `SystemHomeKitAuthorizer()` alone (as `HomeKitAuthorizationTests`
/// exercises for real) never touches HomeKit at all - only calling
/// `currentAuthorizationStatus()` would.
public final class SystemHomeKitAuthorizer: HomeKitAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> HMHomeManagerAuthorizationStatus {
        HMHomeManager().authorizationStatus
    }
}
