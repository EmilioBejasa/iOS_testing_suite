#if os(iOS)
import HealthKit

/// Deterministic stand-in for `SystemHealthAuthorizer` - safe to exercise in
/// any test, since it never touches the real health store or shows a system
/// prompt. `currentAuthorizationStatus(for:)` ignores its `type` parameter
/// and returns the one stored `status` - a per-type dictionary would be
/// premature abstraction nothing in this kit needs yet.
public final class MockHealthAuthorizer: HealthAuthorizing {
    public var status: HKAuthorizationStatus
    public var accessResult: Bool

    public init(status: HKAuthorizationStatus = .notDetermined, accessResult: Bool = true) {
        self.status = status
        self.accessResult = accessResult
    }

    public func currentAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        status
    }

    public func requestAuthorization(
        toShare shareTypes: Set<HKSampleType>,
        read readTypes: Set<HKObjectType>
    ) async -> Bool {
        accessResult
    }
}
#endif
