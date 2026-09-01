import SwiftUI

struct QuoteView: View {
    let store: QuoteStore
    let tipJarStore: TipJarStore

    var body: some View {
        ScrollView {
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
                            Task { await store.toggleFavoriteForCurrentQuote() }
                        }
                        .accessibilityIdentifier("quote.favoriteButton")
                    }
                }

                Toggle("Daily Reminder", isOn: Binding(
                    get: { store.reminderState == .scheduled },
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

                switch tipJarStore.state {
                case .purchased:
                    Text("Thanks for your support!")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("tipJar.thankYou")
                case .failed:
                    Text("Tip Jar isn't available right now.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("tipJar.unavailable")
                case .idle, .purchasing:
                    Button("Tip Jar") {
                        Task { await tipJarStore.purchaseTip() }
                    }
                    .disabled(tipJarStore.state == .purchasing)
                    .accessibilityIdentifier("tipJar.button")
                }

                switch tipJarStore.supporterState {
                case .active:
                    Text("Thanks for being a supporter!")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("supporter.thankYou")
                case .failed:
                    Text("Supporter subscription isn't available right now.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("supporter.unavailable")
                case .idle, .purchasing:
                    Button("Become a Supporter") {
                        Task { await tipJarStore.purchaseSupporterSubscription() }
                    }
                    .disabled(tipJarStore.supporterState == .purchasing)
                    .accessibilityIdentifier("supporter.button")
                }
            }
            .padding()
        }
        .task {
            if case .idle = store.state {
                await store.fetchNewQuote()
            }
            await tipJarStore.refreshSupporterStatus()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            ProgressView("Loading...")
                .accessibilityIdentifier("quote.loading")
        case .loaded(let quote):
            QuoteContentView(quote: quote, usesNewLayout: store.usesNewQuoteLayout)
        case .error(let message):
            Text(message)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("quote.errorMessage")
        }
    }
}
