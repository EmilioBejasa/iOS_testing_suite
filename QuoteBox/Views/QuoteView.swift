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
                .disabled(!store.canFetchNewQuote)
                .accessibilityIdentifier("quote.newButton")

                if case .loaded = store.state {
                    Button(store.isCurrentQuoteFavorited ? "Unfavorite" : "Favorite") {
                        store.toggleFavoriteForCurrentQuote()
                    }
                    .accessibilityIdentifier("quote.favoriteButton")
                }
            }

            Toggle("Daily Reminder", isOn: Binding(
                get: { store.reminderState == .on },
                set: { _ in Task { await store.toggleDailyReminder() } }
            ))
            .accessibilityIdentifier("quote.reminderToggle")

            if store.reminderState == .deniedPermission {
                Text("Notifications are disabled. Enable them in Settings to get a daily reminder.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("quote.reminderDeniedMessage")
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
