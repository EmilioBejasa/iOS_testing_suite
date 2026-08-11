import SwiftUI

struct RootView: View {
    enum Tab {
        case quote
        case favorites
    }

    @State private var store: QuoteStore
    @State private var selectedTab: Tab = .quote
    @Binding private var route: QuoteBoxRoute?

    init(store: QuoteStore, route: Binding<QuoteBoxRoute?>) {
        _store = State(initialValue: store)
        _route = route
        if case .favorites = route.wrappedValue {
            _selectedTab = State(initialValue: .favorites)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            QuoteView(store: store)
                .tabItem {
                    Label("Quote", systemImage: "quote.bubble")
                        .accessibilityIdentifier("tab.quote")
                }
                .tag(Tab.quote)

            FavoritesView(store: store)
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                        .accessibilityIdentifier("tab.favorites")
                }
                .tag(Tab.favorites)
        }
        // Handles a route arriving after this view is already on screen (a real
        // .onOpenURL while the app is running) - the initializer above only
        // covers the route being known up front (cold launch, including the
        // --deep-link test launch argument).
        .onChange(of: route) { _, newRoute in
            if case .favorites = newRoute {
                selectedTab = .favorites
            }
        }
    }
}
