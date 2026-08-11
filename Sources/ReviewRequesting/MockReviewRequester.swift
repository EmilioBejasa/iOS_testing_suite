/// Deterministic stand-in for `SystemReviewRequester` - records how many times
/// it was asked, since that's the only thing worth verifying about a call this
/// opaque even for the real implementation.
public final class MockReviewRequester: ReviewRequesting {
    public private(set) var requestCount = 0

    public init() {}

    public func requestReview() {
        requestCount += 1
    }
}
