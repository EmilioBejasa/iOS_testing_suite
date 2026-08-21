#if canImport(ActivityKit)
import ActivityKit

/// Wraps `ActivityAuthorizationInfo().areActivitiesEnabled` - a plain,
/// synchronous read. No entitlement, no prompt (confirmed via WebSearch
/// before writing this).
@available(iOS 16.1, *)
public final class SystemLiveActivityAuthorizer: LiveActivityAuthorizing {
    public init() {}

    public var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
}
#endif
