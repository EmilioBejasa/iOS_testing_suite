#if os(iOS)
import CoreMotion

/// Wraps `CMMotionActivityManager.authorizationStatus()` - a static,
/// synchronous, non-prompting read. No bridging needed, unlike every module
/// with an explicit request call.
public final class SystemMotionAuthorizer: MotionAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> CMAuthorizationStatus {
        CMMotionActivityManager.authorizationStatus()
    }
}
#endif
