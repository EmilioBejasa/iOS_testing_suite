#if os(iOS)
import CoreTelephony

/// Wraps `CTCellularData().restrictedState` - a plain, synchronous
/// CoreTelephony read. No entitlement required (confirmed before writing
/// this - unlike most CoreTelephony APIs, `CTCellularData` doesn't need one),
/// available since iOS 9, well under the package's iOS 13 floor.
public final class SystemCellularDataChecker: CellularDataRestrictionChecking {
    private let cellularData = CTCellularData()

    public init() {}

    public func currentRestrictedState() -> CTCellularDataRestrictedState {
        cellularData.restrictedState
    }
}
#endif
