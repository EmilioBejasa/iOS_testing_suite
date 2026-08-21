#if os(iOS)
import XCTest
import CoreTelephony
import CellularDataRestrictionChecking

final class CellularDataRestrictionCheckingTests: XCTestCase {
    func testMockReturnsConfiguredState() {
        let checker = MockCellularDataChecker(state: .restricted)

        XCTAssertEqual(checker.currentRestrictedState(), .restricted)
    }

    func testMockDefaultsToUnknown() {
        let checker = MockCellularDataChecker()

        XCTAssertEqual(checker.currentRestrictedState(), .restrictedStateUnknown)
    }

    /// CTCellularData needs no entitlement (confirmed before writing this
    /// module - unlike most CoreTelephony APIs), so exercising the real
    /// checker's status read is expected to be safe. A fresh Simulator with
    /// no cellular hardware should report .restrictedStateUnknown rather than
    /// crashing - this assertion proves only "doesn't crash or hang," not any
    /// particular state value, same as the other status-read-only tests.
    func testSystemCheckerReadsStateWithoutCrashing() {
        let checker = SystemCellularDataChecker()

        _ = checker.currentRestrictedState()
    }
}
#endif
