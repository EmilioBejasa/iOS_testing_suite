import SwiftUI

struct RootView: View {
    @State private var store: QuoteStore

    init(store: QuoteStore) {
        _store = State(initialValue: store)
    }

    var body: some View {
        TabView {
            QuoteView(store: store)
                .tabItem {
                    Label("Quote", systemImage: "quote.bubble")
                        .accessibilityIdentifier("tab.quote")
                }

            FavoritesView(store: store)
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                        .accessibilityIdentifier("tab.favorites")
                }
        }
    }
}
