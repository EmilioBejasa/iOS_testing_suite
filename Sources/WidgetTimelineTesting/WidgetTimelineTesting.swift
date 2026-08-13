import WidgetKit

/// Bridges WidgetKit's completion-handler-based timeline provider to
/// `async` - the same category of value `SystemSleeper` provides over raw
/// `Task.sleep`: `getTimeline(in:completion:)` predates Swift concurrency
/// and has no `async` variant of its own.
///
/// Deliberately doesn't constrain to Apple's own `TimelineProvider`
/// protocol: `TimelineProviderContext` has no public initializer (the same
/// "framework type with no public init" problem `MockPurchaseManager`'s doc
/// comment documents for StoreKit's `Product`), so a test could never
/// construct one to drive a real `TimelineProvider` with. This protocol is
/// structurally equivalent instead, with a generic `Context` associated
/// type - a real widget's provider satisfies it with a one-line added
/// conformance, while a test passes a lightweight local `Context` type it
/// can actually construct.
@available(iOS 14.0, *)
public protocol TimelineProviding {
    associatedtype Entry: TimelineEntry
    associatedtype Context
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void)
}

@available(iOS 14.0, *)
public enum WidgetTimelineTesting {
    /// Bridges `provider.getTimeline(in:completion:)` to `async`, so a test
    /// can `await` a timeline instead of juggling an `XCTestExpectation`.
    public static func collectTimeline<P: TimelineProviding>(
        from provider: P,
        in context: P.Context
    ) async -> Timeline<P.Entry> {
        await withCheckedContinuation { continuation in
            provider.getTimeline(in: context) { timeline in
                continuation.resume(returning: timeline)
            }
        }
    }
}
