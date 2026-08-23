import ClipboardProviding
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
    private let launchCount: Int
    private let didRequestReviewThisLaunch: Bool
    private let clipboardRoundTripResult: String?

    /// Not a real secret - only needs to be a value the UI test can assert on
    /// verbatim after the round trip.
    private static let clipboardRoundTripToken = "QuoteBoxClipboardRoundTrip"

    init(
        store: QuoteStore,
        tipJarStore: TipJarStore,
        launchCount: Int,
        didRequestReviewThisLaunch: Bool,
        route: Binding<QuoteBoxRoute?>
    ) {
        _store = State(initialValue: store)
        _tipJarStore = State(initialValue: tipJarStore)
        self.launchCount = launchCount
        self.didRequestReviewThisLaunch = didRequestReviewThisLaunch
        _route = route
        if case .favorites = route.wrappedValue {
            _selectedTab = State(initialValue: .favorites)
        }

        // --real-clipboard drives a same-process copy-then-read against the
        // real pasteboard, surfaced on the Debug tab. See
        // ClipboardProvidingTests.testSystemProviderRoundTripsAgainstRealPasteboard's
        // doc comment / CONTRIBUTING.md's Troubleshooting table for why the
        // equivalent bare-XCTest-bundle round trip hangs on iOS 16+'s
        // paste-permission alert - the theory here is that a real app reading
        // clipboard content it just wrote itself, from inside its own bundle
        // identity, is the same-source case that alert is documented to exempt.
        if ProcessInfo.processInfo.arguments.contains("--real-clipboard") {
            let clipboard = SystemClipboardProvider()
            clipboard.copy(Self.clipboardRoundTripToken)
            clipboardRoundTripResult = clipboard.currentString() ?? "nil"
        } else {
            clipboardRoundTripResult = nil
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
        var sections: [DebugSection] = [
            .launchArguments(),
            DebugSection("App", rows: [
                DebugRow("Launch Count", "\(launchCount)"),
                DebugRow("Requested Review This Launch", "\(didRequestReviewThisLaunch)")
            ]),
            DebugSection("Quote", rows: [
                DebugRow("State", String(describing: store.state)),
                DebugRow("Favorites", "\(store.favorites.count)"),
                DebugRow("Reminder", String(describing: store.reminderState)),
                DebugRow("Network", String(describing: store.networkStatus))
            ]),
            DebugSection("Tip Jar", rows: [
                DebugRow("State", String(describing: tipJarStore.state))
            ])
        ]
        if let clipboardRoundTripResult {
            sections.append(DebugSection("Clipboard", rows: [
                DebugRow("Round Trip", clipboardRoundTripResult)
            ]))
        }
        return sections
    }
    #endif
}
