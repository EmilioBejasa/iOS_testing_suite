import WidgetKit
import WidgetTimelineTesting

struct QuoteWidgetEntry: TimelineEntry {
    let date: Date
    let quoteText: String
    let author: String
}

/// The widget's actual timeline-building logic, kept separate from
/// `QuoteWidgetProvider` (the WidgetKit-facing type registered with
/// `StaticConfiguration`, whose `Context` is fixed to `TimelineProviderContext`
/// via `TimelineProvider`'s own `typealias`). Conforming *this* type to the
/// kit's `TimelineProviding` instead - with `Context = Void` - is what makes
/// it testable at all: `TimelineProviderContext` has no public initializer
/// (see `TimelineProviding`'s own doc comment), so a test could never
/// construct one to drive `QuoteWidgetProvider` directly.
struct QuoteWidgetCore: TimelineProviding {
    static let appGroupSuiteName = "group.com.quotebox.qa"
    static let sharedQuoteKey = "currentQuote"

    static let placeholderEntry = QuoteWidgetEntry(
        date: Date(),
        quoteText: "The only way to do great work is to love what you do.",
        author: "Steve Jobs"
    )

    private struct SharedQuotePayload: Decodable {
        let quote: String
        let author: String
    }

    func getTimeline(in context: Void, completion: @escaping (Timeline<QuoteWidgetEntry>) -> Void) {
        completion(Timeline(entries: [Self.currentEntry()], policy: .never))
    }

    /// Falls back to `placeholderEntry` both before the host app has ever
    /// shared a quote (first widget add, before `QuoteStore.fetchNewQuote()`
    /// has run once) and if the shared container is unreachable for any
    /// reason - a widget should never render nothing.
    static func currentEntry() -> QuoteWidgetEntry {
        guard
            let defaults = UserDefaults(suiteName: appGroupSuiteName),
            let data = defaults.data(forKey: sharedQuoteKey),
            let payload = try? JSONDecoder().decode(SharedQuotePayload.self, from: data)
        else {
            return placeholderEntry
        }
        return QuoteWidgetEntry(date: Date(), quoteText: payload.quote, author: payload.author)
    }
}
