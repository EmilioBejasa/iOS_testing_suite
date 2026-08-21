#if os(iOS)
import CoreTelephony

/// Deterministic stand-in for `SystemCellularDataChecker` - safe to exercise
/// in any test, since it never touches the real cellular data state.
public final class MockCellularDataChecker: CellularDataRestrictionChecking {
    public var state: CTCellularDataRestrictedState

    public init(state: CTCellularDataRestrictedState = .restrictedStateUnknown) {
        self.state = state
    }

    public func currentRestrictedState() -> CTCellularDataRestrictedState {
        state
    }
}
#endif
