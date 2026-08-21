#if canImport(CoreTelephony)
import CoreTelephony

/// Lets app code ask "has the user restricted this app from cellular data?"
/// (Settings > Cellular > per-app toggle) through an injectable dependency.
/// Uses `CTCellularDataRestrictedState` directly, same reasoning every other
/// module here gives for keeping a framework's own status type.
public protocol CellularDataRestrictionChecking {
    func currentRestrictedState() -> CTCellularDataRestrictedState
}
#endif
