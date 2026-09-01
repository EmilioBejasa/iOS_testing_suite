import SwiftUI

/// The quote-display portion of `QuoteView`'s `.loaded` state, split out as its
/// own small, purely-presentational view — easy to snapshot-test in isolation
/// without pulling in `ScrollView`/`Toggle`/`QuoteStore`, none of which
/// `ImageRenderer` renders reliably off-screen.
struct QuoteContentView: View {
    let quote: Quote
    /// Gated by `FeatureFlagging`'s `"newQuoteLayout"` flag, resolved by
    /// `QuoteStore.usesNewQuoteLayout` and passed down as a plain `Bool` by
    /// `QuoteView` — this view stays dependency-free. Defaults `false` so
    /// existing call sites keep rendering the original layout unchanged.
    var usesNewLayout: Bool = false

    var body: some View {
        if usesNewLayout {
            VStack(alignment: .leading, spacing: 8) {
                Text("“")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(quote.quote)
                    .font(.title3)
                    .multilineTextAlignment(.leading)
                    .accessibilityIdentifier("quote.text")
                Text("— \(quote.author)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("quote.author")
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        } else {
            VStack(spacing: 8) {
                Text(quote.quote)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("quote.text")
                Text("— \(quote.author)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("quote.author")
            }
        }
    }
}
