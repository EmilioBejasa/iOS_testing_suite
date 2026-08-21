import XCTest
import DiskSpaceChecking

final class DiskSpaceCheckingTests: XCTestCase {
    func testMockReturnsConfiguredCapacities() {
        let checker = MockDiskSpaceChecker(available: 1_000, total: 2_000)

        XCTAssertEqual(checker.availableCapacity(), 1_000)
        XCTAssertEqual(checker.totalCapacity(), 2_000)
    }

    func testMockDefaultsToNonNilCapacities() {
        let checker = MockDiskSpaceChecker()

        XCTAssertNotNil(checker.availableCapacity())
        XCTAssertNotNil(checker.totalCapacity())
    }

    func testMockCanSimulateUnavailableCapacity() {
        let checker = MockDiskSpaceChecker(available: nil, total: nil)

        XCTAssertNil(checker.availableCapacity())
        XCTAssertNil(checker.totalCapacity())
    }

    /// Safe to exercise for real - a plain, synchronous, non-prompting
    /// Foundation read against the app's own home directory, no UIKit/
    /// MainActor concern. Asserts the values are positive and internally
    /// consistent (available <= total) rather than any specific number,
    /// since the real figures depend entirely on the CI Simulator host's
    /// actual disk state.
    func testSystemCheckerReadsPositiveConsistentCapacities() throws {
        let checker = SystemDiskSpaceChecker()

        let available = try XCTUnwrap(checker.availableCapacity())
        let total = try XCTUnwrap(checker.totalCapacity())

        XCTAssertGreaterThan(available, 0)
        XCTAssertGreaterThan(total, 0)
        XCTAssertLessThanOrEqual(available, total)
    }
}
