#if canImport(HealthKit)
import HealthKit

/// A tenth permission-gated system service, same protocol+real+fake shape as
/// `ContactsAuthorization`. Uses `HKAuthorizationStatus` directly, same
/// reasoning every other module here gives for keeping a framework's own
/// status type. Parameterized by `HKObjectType` rather than a single fixed
/// data type, since HealthKit authorization is always scoped per data type -
/// there's no single "is HealthKit authorized" status the way Contacts or
/// Photos have.
public protocol HealthAuthorizing {
    func currentAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus
    func requestAuthorization(toShare shareTypes: Set<HKSampleType>, read readTypes: Set<HKObjectType>) async -> Bool
}
#endif
