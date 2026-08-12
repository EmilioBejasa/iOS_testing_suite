import FamilyControls

/// Wraps `AuthorizationCenter.shared`. `requestAuthorization(for:)` is
/// already a native `async throws` API (unlike Siri/Focus Status's
/// completion-handler shape) - any thrown error (including a missing
/// entitlement) collapses to `false`, the same "collapse thrown error"
/// pattern `CloudKitAccountChecking` uses for `CKContainer.accountStatus()`.
@available(iOS 16.0, *)
public final class SystemFamilyControlsAuthorizer: FamilyControlsAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> AuthorizationStatus {
        AuthorizationCenter.shared.authorizationStatus
    }

    public func requestAuthorization() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            return true
        } catch {
            return false
        }
    }
}
