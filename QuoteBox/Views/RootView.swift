import DebugOverlay
import SwiftUI

struct RootView: View {
    enum Tab {
        case quote
        case favorites
        #if DEBUG
        case debug
        #endif
    }

    @State private var store: QuoteStore
    @State private var tipJarStore: TipJarStore
    @State private var selectedTab: Tab = .quote
    @Binding private var route: QuoteBoxRoute?

    init(store: QuoteStore, tipJarStore: TipJarStore, route: Binding<QuoteBoxRoute?>) {
        _store = State(initialValue: store)
        _tipJarStore = State(initialValue: tipJarStore)
        _route = route
        if case .favorites = route.wrappedValue {
            _selectedTab = State(initialValue: .favorites)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            QuoteView(store: store, tipJarStore: tipJarStore)
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

            #if DEBUG
            DebugOverlayView(sections: debugSections)
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                        .accessibilityIdentifier("tab.debug")
                }
                .tag(Tab.debug)
            #endif
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

    #if DEBUG
    private var debugSections: [DebugSection] {
        [
            .launchArguments(),
            DebugSection("Quote", rows: [
                DebugRow("State", String(describing: store.state)),
                DebugRow("Favorites", "\(store.favorites.count)"),
                DebugRow("Reminder", String(describing: store.reminderState)),
            ]),
            DebugSection("Tip Jar", rows: [
                DebugRow("State", String(describing: tipJarStore.state)),
            ]),
        ]
    }
    #endif
}
