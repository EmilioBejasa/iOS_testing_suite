#if os(iOS)
import HealthKit

/// Wraps `HKHealthStore`. Deliberately bridges the older completion-handler
/// `requestAuthorization(toShare:read:completion:)` (available since iOS 8)
/// via `CheckedContinuation` rather than adopting the iOS 15+ native `async
/// throws` overload - keeps this module at the package's iOS 13 floor with no
/// extra `@available` annotations needed anywhere, same reasoning
/// `MicrophoneAuthorization` gives for avoiding `AVAudioApplication`.
public final class SystemHealthAuthorizer: HealthAuthorizing {
    private let store = HKHealthStore()

    public init() {}

    public func currentAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        store.authorizationStatus(for: type)
    }

    public func requestAuthorization(
        toShare shareTypes: Set<HKSampleType>,
        read readTypes: Set<HKObjectType>
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            store.requestAuthorization(toShare: shareTypes, read: readTypes) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
#endif
