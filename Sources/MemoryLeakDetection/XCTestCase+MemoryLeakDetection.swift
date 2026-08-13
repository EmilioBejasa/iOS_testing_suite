import XCTest

/// A third module shape, alongside `UITestHelpers`: an `XCTestCase`
/// extension usable only from a test target, not a protocol+`System`+`Mock`
/// triad or a pure-function utility - deallocation tracking has no real
/// system framework to wrap or fake, it's a property of ARC itself.
public extension XCTestCase {
    /// Registers a teardown block asserting `instance` has been deallocated
    /// by the end of the test. Call this right after constructing whatever
    /// you're tracking, holding no other strong reference to it for the rest
    /// of the test - a passing assertion after teardown means nothing else
    /// (a delegate closure, an async subscription, a parent-child retain
    /// cycle) is still keeping it alive.
    func trackForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should have been deallocated. Potential memory leak.",
                file: file,
                line: line
            )
        }
    }
}
