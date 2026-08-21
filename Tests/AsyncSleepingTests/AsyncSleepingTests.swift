import XCTest
import AsyncSleeping

@available(iOS 16.0, *)
final class AsyncSleepingTests: XCTestCase {
    func testMockRecordsRequestedDurations() async throws {
        let sleeper = MockSleeper()

        try await sleeper.sleep(for: .seconds(5))
        try await sleeper.sleep(for: .milliseconds(250))

        XCTAssertEqual(sleeper.requestedDurations, [.seconds(5), .milliseconds(250)])
    }

    func testMockReturnsWithoutActuallyWaiting() async throws {
        let sleeper = MockSleeper()
        let start = Date()

        try await sleeper.sleep(for: .seconds(30))

        XCTAssertLessThan(Date().timeIntervalSince(start), 1)
    }

    /// Unlike the permission-gated modules above, there's no system prompt or
    /// crash risk here - just an actual (brief) wait, so this is exercised
    /// for real rather than status-only.
    func testSystemSleeperActuallyWaits() async throws {
        let sleeper = SystemSleeper()
        let start = Date()

        try await sleeper.sleep(for: .milliseconds(50))

        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 0.05)
    }
}
