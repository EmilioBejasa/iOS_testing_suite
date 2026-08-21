/// Not a protocol+real+fake module - there's nothing to fake, it's already a
/// pure, deterministic function - same "single-purpose utility" shape as
/// `JSONFixtureLoading`/`DeepLinkTesting`. Complements `AsyncSleeping`'s
/// "inject the wait" with "wait for the result": `AsyncSleeping` lets app
/// code ask "wait this long" through an injectable dependency, while this
/// lets a *test* await a bounded number of elements from a long-lived
/// `AsyncSequence` without hanging forever if fewer than expected ever
/// arrive.
///
/// Deliberately covers `AsyncSequence`, not Combine: no `import Combine`
/// exists anywhere in this kit or in QuoteBox (`TipJarStore` is
/// `@Observable`, not `ObservableObject`), so bridging Combine publishers
/// here would fake a paradigm this kit's own consumer app never uses - the
/// same "don't fake a capability this kit doesn't have" reasoning the
/// README gives for excluding CarPlay/MultipeerConnectivity/Core NFC.
/// `AsyncSequence` is different: it's what Apple's own frameworks expose
/// today (`Transaction.updates`, `NotificationCenter.notifications(named:)`),
/// including `PurchaseSupport`'s own `Transaction.updates` support.
///
/// `Duration` itself is `@available(iOS 16, *)` in Apple's headers, so
/// merely naming it here requires this annotation too - same reasoning
/// `AsyncSleeping` gives for the same availability gate.
@available(iOS 16.0, *)
public enum AsyncSequenceCollecting {
    /// Thrown when fewer than `count` elements arrive from `sequence` before
    /// `timeout` elapses.
    public enum TimeoutWaitingForElements: Error {
        case timedOut(collected: Int, expected: Int)
    }

    /// Awaits exactly `count` elements from `sequence`, racing iteration
    /// against `timeout` so a test never hangs on a sequence that emits
    /// fewer elements than expected. Throws `.timedOut` (reporting however
    /// many elements did arrive) rather than returning a short array, so a
    /// caller can't mistake "timed out early" for "sequence intentionally
    /// emitted fewer than requested."
    public static func collect<S: AsyncSequence>(
        _ sequence: S,
        count: Int,
        timeout: Duration
    ) async throws -> [S.Element] {
        let accumulator = Accumulator<S.Element>()

        return try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for try await element in sequence where await accumulator.append(element, target: count) {
                    return
                }
            }
            group.addTask {
                try await Task.sleep(for: timeout)
            }

            _ = try await group.next()
            group.cancelAll()

            let collected = await accumulator.elements
            guard collected.count >= count else {
                throw TimeoutWaitingForElements.timedOut(collected: collected.count, expected: count)
            }
            return collected
        }
    }

    private actor Accumulator<Element> {
        private(set) var elements: [Element] = []

        func append(_ element: Element, target: Int) -> Bool {
            elements.append(element)
            return elements.count >= target
        }
    }
}
