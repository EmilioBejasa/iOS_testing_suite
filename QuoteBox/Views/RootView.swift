import ClipboardProviding
import DebugOverlay
import DiagnosticReporting
import LocalNotifications
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
    private let appVersionString: String
    private let didStartDiagnosticReportingThisLaunch: Bool
    private let clipboardRoundTripResult: String?
    private let notificationsCancelResult: String?
    private let diagnosticsStartStopResult: String?

    /// Not a real secret - only needs to be a value the UI test can assert on
    /// verbatim after the round trip. Kept short: the Debug tab's row value
    /// `Text` has no line-limit/wrap handling, and a longer token got clipped
    /// on iPhone SE's narrower width (caught by
    /// testDebugTabShowsRealClipboardRoundTrip's accessibility audit in CI).
    private static let clipboardRoundTripToken = "clip-ok"

    init(
        store: QuoteStore,
        tipJarStore: TipJarStore,
        launchCount: Int,
        didRequestReviewThisLaunch: Bool,
        appVersionString: String,
        didStartDiagnosticReportingThisLaunch: Bool,
        route: Binding<QuoteBoxRoute?>
    ) {
        _store = State(initialValue: store)
        _tipJarStore = State(initialValue: tipJarStore)
        self.launchCount = launchCount
        self.didRequestReviewThisLaunch = didRequestReviewThisLaunch
        self.appVersionString = appVersionString
        self.didStartDiagnosticReportingThisLaunch = didStartDiagnosticReportingThisLaunch
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

        // --real-notifications constructs SystemReminderScheduler for real and
        // calls its one non-prompting method, surfaced on the Debug tab. This
        // is deliberately narrower than the clipboard/purchase real-paths:
        // SystemReminderScheduler's default `center` argument crashes outside a
        // real host app bundle (CONTRIBUTING.md's Troubleshooting table), so
        // this closes that half of the gap. requestAuthorization()/
        // scheduleDailyReminder() stay untested for real - QuoteStore's only
        // path to scheduleDailyReminder goes through requestAuthorization()
        // first, which triggers a real, un-dismissable-by-construction system
        // permission dialog with no same-process loophole like Clipboard's.
        if ProcessInfo.processInfo.arguments.contains("--real-notifications") {
            let scheduler = SystemReminderScheduler()
            scheduler.cancelDailyReminder()
            notificationsCancelResult = "ok"
        } else {
            notificationsCancelResult = nil
        }

        diagnosticsStartStopResult = Self.resolveDiagnosticsStartStopResult()
    }

    // --real-diagnostics constructs SystemDiagnosticReporter for real and
    // calls both startReporting()/stopReporting(), surfaced on the Debug tab.
    // QuoteBoxApp's own diagnosticReporter (production or mock, depending on
    // launch mode) only ever calls startReporting() once at launch -
    // stopReporting() otherwise goes uncalled anywhere in the app, the same
    // gap the clipboard/notifications blocks above close for their own
    // protocols. MXMetricManager.remove(subscriber:) is safe to call on a
    // subscriber that was just added by this same instance, so this is a
    // genuine same-process round trip rather than a no-op. Split out of
    // init() to keep its body under function_body_length's limit (889f39a
    // already hit this once for makeDependencies).
    private static func resolveDiagnosticsStartStopResult() -> String? {
        guard ProcessInfo.processInfo.arguments.contains("--real-diagnostics") else { return nil }
        let reporter = SystemDiagnosticReporter()
        reporter.startReporting()
        reporter.stopReporting()
        return "ok"
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
                DebugRow("Requested Review This Launch", "\(didRequestReviewThisLaunch)"),
                DebugRow("Version", appVersionString),
                DebugRow("Diagnostic Reporting Started", "\(didStartDiagnosticReportingThisLaunch)")
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
        if let notificationsCancelResult {
            sections.append(DebugSection("Notifications", rows: [
                DebugRow("Cancel Call", notificationsCancelResult)
            ]))
        }
        if let diagnosticsStartStopResult {
            sections.append(DebugSection("Diagnostics", rows: [
                DebugRow("Start/Stop Call", diagnosticsStartStopResult)
            ]))
        }
        return sections
    }
    #endif
}
