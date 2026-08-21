#if canImport(FamilyControls)
import FamilyControls

/// Deterministic stand-in for `SystemFamilyControlsAuthorizer` - safe to
/// exercise in any test, since it never touches the real authorization
/// center or shows a system prompt.
@available(iOS 16.0, *)
public final class MockFamilyControlsAuthorizer: FamilyControlsAuthorizing {
    public var status: AuthorizationStatus
    public var accessResult: Bool

    public init(status: AuthorizationStatus = .notDetermined, accessResult: Bool = true) {
        self.status = status
        self.accessResult = accessResult
    }

    public func currentAuthorizationStatus() -> AuthorizationStatus {
        status
    }

    public func requestAuthorization() async -> Bool {
        accessResult
    }
}
#endif
