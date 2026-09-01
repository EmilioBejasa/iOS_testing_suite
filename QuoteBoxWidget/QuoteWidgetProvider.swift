import WidgetKit

/// Thin WidgetKit-facing adapter over `QuoteWidgetCore` - see that type's
/// doc comment for why the actual logic lives there instead of here.
struct QuoteWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteWidgetEntry {
        QuoteWidgetCore.placeholderEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteWidgetEntry) -> Void) {
        completion(QuoteWidgetCore.currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteWidgetEntry>) -> Void) {
        QuoteWidgetCore().getTimeline(in: (), completion: completion)
    }
}
