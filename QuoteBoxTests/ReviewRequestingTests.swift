import XCTest
import ReviewRequesting

final class ReviewRequestingTests: XCTestCase {
    func testMockRecordsRequestCount() {
        let requester = MockReviewRequester()

        requester.requestReview()
        requester.requestReview()

        XCTAssertEqual(requester.requestCount, 2)
    }

    func testMockStartsAtZero() {
        let requester = MockReviewRequester()

        XCTAssertEqual(requester.requestCount, 0)
    }

    /// Unlike PushRegistering/AppleSignIn's prompting halves, this is safe to
    /// call for real: AppStore.requestReview(in:) never guarantees showing UI
    /// (the system rate-limits and decides on its own), so there's no dialog
    /// XCTest could get stuck on. QuoteBoxTests runs hosted inside the real
    /// QuoteBox app process, so a real foreground UIWindowScene exists to find.
    /// Nothing to assert beyond "doesn't crash or hang" - same as the real
    /// system's own API contract offers any caller.
    func testSystemRequesterCallsWithoutCrashing() {
        let requester = SystemReviewRequester()

        requester.requestReview()
    }
}
