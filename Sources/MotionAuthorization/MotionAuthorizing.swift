#if canImport(CoreMotion)
import CoreMotion

/// An eleventh permission-gated system service - but unlike every other
/// authorization module in this kit, there's no explicit "request
/// authorization" API here: Core Motion prompts implicitly the first time the
/// app starts using the service (`CMMotionActivityManager.startActivityUpdates`),
/// not via a separate async call. So this protocol only has a status read.
/// Uses `CMAuthorizationStatus` directly, same reasoning every other module
/// here gives for keeping a framework's own status type.
public protocol MotionAuthorizing {
    func currentAuthorizationStatus() -> CMAuthorizationStatus
}
#endif
