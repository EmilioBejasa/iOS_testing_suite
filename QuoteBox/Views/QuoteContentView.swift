import SwiftUI

/// The quote-display portion of `QuoteView`'s `.loaded` state, split out as its
/// own small, purely-presentational view — easy to snapshot-test in isolation
/// without pulling in `ScrollView`/`Toggle`/`QuoteStore`, none of which
/// `ImageRenderer` renders reliably off-screen.
struct QuoteContentView: View {
    let quote: Quote

    var body: some View {
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
