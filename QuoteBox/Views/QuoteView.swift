import SwiftUI

struct QuoteView: View {
    let store: QuoteStore

    var body: some View {
        VStack(spacing: 20) {
            content
            HStack(spacing: 16) {
                Button("New Quote") {
                    Task { await store.fetchNewQuote() }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("quote.newButton")

                if case .loaded = store.state {
                    Button(store.isCurrentQuoteFavorited ? "Unfavorite" : "Favorite") {
                        store.toggleFavoriteForCurrentQuote()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("quote.favoriteButton")
                }
            }
        }
        .padding()
        .task {
            if case .idle = store.state {
                await store.fetchNewQuote()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            ProgressView("Loading...")
                .accessibilityIdentifier("quote.loading")
        case .loaded(let quote):
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
        case .error(let message):
            Text(message)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("quote.errorMessage")
        }
    }
}
