import ActivityKit

/// No explicit request API - the user manages Live Activities via Settings,
/// not an in-app prompt, same structural shape as `MotionAuthorizing`/
/// `BluetoothAuthorizing`.
///
/// `ActivityAuthorizationInfo` itself is `@available(iOS 16.1, *)` in
/// Apple's headers (confirmed via WebSearch before writing this) - newer
/// than the package's iOS 13 floor - so merely naming the type here requires
/// this annotation on the protocol, `SystemLiveActivityAuthorizer`, AND
/// `MockLiveActivityAuthorizer` alike, the same class of fix
/// `BluetoothAuthorizing` needed for `CBManagerAuthorization`. Applied here
/// from the start rather than discovered via a failed CI run.
@available(iOS 16.1, *)
public protocol LiveActivityAuthorizing {
    var areActivitiesEnabled: Bool { get }
}
