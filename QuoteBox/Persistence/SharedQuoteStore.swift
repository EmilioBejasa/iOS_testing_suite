import Foundation

/// Writes the current quote to the App Group `UserDefaults` suite the
/// `QuoteBoxWidget` extension reads from - a separate, sandboxed process
/// that can't otherwise see this app's in-memory `QuoteStore` state.
/// `UserDefaultsStoring` (the kit's abstraction, `Sources/UserDefaultsStore`)
/// deliberately only covers int/bool per its own doc comment ("rather than a
/// generic Codable wrapper"), so this is QuoteBox-specific glue rather than
/// something that belongs in the kit. The widget extension decodes the same
/// JSON shape independently (`QuoteBoxWidget/QuoteWidgetCore.swift`) rather
/// than sharing this type, since the two targets don't share source files.
protocol SharedQuoteWriting {
    func save(_ quote: Quote)
}

final class SystemSharedQuoteStore: SharedQuoteWriting {
    static let appGroupSuiteName = "group.com.quotebox.qa"
    static let sharedQuoteKey = "currentQuote"

    private struct Payload: Encodable {
        let quote: String
        let author: String
    }

    private let defaults: UserDefaults?

    init(suiteName: String = SystemSharedQuoteStore.appGroupSuiteName) {
        defaults = UserDefaults(suiteName: suiteName)
    }

    func save(_ quote: Quote) {
        guard let data = try? JSONEncoder().encode(Payload(quote: quote.quote, author: quote.author)) else { return }
        defaults?.set(data, forKey: Self.sharedQuoteKey)
    }
}

/// `QuoteStore`'s default - every test-constructed `QuoteStore` (there are
/// many, across `QuoteBoxTests`) would otherwise write real, unmocked data
/// into the same App Group suite `QuoteWidgetCoreTests` seeds and reads
/// from directly, racing with it. Only `QuoteBoxApp.swift`'s real
/// (non-`--mock-*`) branch passes `SystemSharedQuoteStore()` explicitly -
/// the same swap-in-the-real-implementation pattern already used for
/// `reminderScheduler`/`purchaseManager`.
final class NoOpSharedQuoteWriter: SharedQuoteWriting {
    func save(_ quote: Quote) {}
}
