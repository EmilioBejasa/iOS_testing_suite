#if os(iOS)
/// Deterministic stand-in for `SystemLiveActivityAuthorizer` - safe to
/// exercise in any test, since it never touches the real ActivityKit
/// runtime.
@available(iOS 16.1, *)
public final class MockLiveActivityAuthorizer: LiveActivityAuthorizing {
    public var areActivitiesEnabled: Bool

    public init(areActivitiesEnabled: Bool = false) {
        self.areActivitiesEnabled = areActivitiesEnabled
    }
}
#endif
