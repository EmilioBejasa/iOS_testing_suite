import XCTest
import AsyncSleeping

// SCRATCH: one-off benchmark to get real numbers for the README's "how much
// faster" claim, run once in CI and then deleted - not meant to stay in the
// suite (wall-clock-ratio assertions are inherently flaky across runners).
@available(iOS 16.0, *)
final class ScratchBenchmarkTests: XCTestCase {
    func testMockSleeperVsSystemSleeperForRetryBackoffShape() async throws {
        // Matches QuoteStore.retryDelays: [.seconds(1), .seconds(2)].
        let delays: [Duration] = [.seconds(1), .seconds(2)]

        let mockStart = Date()
        let mockSleeper: AsyncSleeping = MockSleeper()
        for delay in delays {
            try await mockSleeper.sleep(for: delay)
        }
        let mockElapsed = Date().timeIntervalSince(mockStart)

        let realStart = Date()
        let realSleeper: AsyncSleeping = SystemSleeper()
        for delay in delays {
            try await realSleeper.sleep(for: delay)
        }
        let realElapsed = Date().timeIntervalSince(realStart)

        print("BENCHMARK_RESULT mock=\(mockElapsed)s real=\(realElapsed)s speedup=\(realElapsed / mockElapsed)x")
    }
}
