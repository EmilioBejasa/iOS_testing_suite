import AnalyticsLogging
import AsyncSleeping
import BundleInfoProviding
import CoreData
import DeepLinkTesting
import DiagnosticReporting
import FeatureFlagging
import LocalNotifications
import NetworkReachabilityMonitoring
import PurchaseSupport
import ReviewRequesting
import SwiftUI
import UserDefaultsStore

@main
struct QuoteBoxApp: App {
    static let reviewRequestThreshold = 3

    private let store: QuoteStore
    private let tipJarStore: TipJarStore
    private let launchCount: Int
    private let didRequestReviewThisLaunch: Bool
    private let appVersionString: String
    private let didStartDiagnosticReportingThisLaunch: Bool
    @State private var route: QuoteBoxRoute?

    private struct Dependencies {
        let apiClient: QuoteAPIClientProtocol
        let favoritesStore: FavoritesStoring
        let reminderScheduler: ReminderScheduling
        let purchaseManager: PurchaseManaging
        let userDefaultsStore: UserDefaultsStoring
        let reachabilityMonitor: NetworkReachabilityMonitoring
        let reviewRequester: ReviewRequesting
        let sharedQuoteStore: SharedQuoteWriting
        let bundleInfo: BundleInfoProviding
        let diagnosticReporter: DiagnosticReporting
        let analyticsLogger: AnalyticsLogging
        let featureFlags: FeatureFlagging
        let sleeper: AsyncSleeping
    }

    private static func makeDependencies(for arguments: [String]) -> Dependencies {
        if arguments.contains("--mock-error") {
            return mockErrorDependencies()
        } else if arguments.contains("--mock-success") {
            return mockSuccessDependencies(for: arguments)
        } else {
            return productionDependencies()
        }
    }

    private static func mockErrorDependencies() -> Dependencies {
        Dependencies(
            apiClient: MockQuoteAPIClient(mode: .failure(.requestFailed)),
            favoritesStore: InMemoryFavoritesStore(),
            reminderScheduler: MockReminderScheduler(authorizationResult: .authorized),
            purchaseManager: MockPurchaseManager(),
            userDefaultsStore: InMemoryUserDefaultsStore(),
            reachabilityMonitor: MockNetworkReachabilityMonitor(currentStatus: .satisfied),
            reviewRequester: MockReviewRequester(),
            sharedQuoteStore: NoOpSharedQuoteWriter(),
            bundleInfo: MockBundleInfoProvider(),
            diagnosticReporter: MockDiagnosticReporter(),
            analyticsLogger: MockAnalyticsLogger(),
            featureFlags: MockFeatureFlags(),
            sleeper: MockSleeper()
        )
    }

    private static func mockSuccessDependencies(for arguments: [String]) -> Dependencies {
        let notificationsDenied = arguments.contains("--mock-notifications-denied")
        let authorizationResult: AuthorizationStatus = notificationsDenied ? .denied : .authorized
        let usesRealPurchases = arguments.contains("--real-purchases")
        return Dependencies(
            apiClient: MockQuoteAPIClient(mode: .success(MockQuoteAPIClient.defaultQuote)),
            favoritesStore: InMemoryFavoritesStore(),
            reminderScheduler: MockReminderScheduler(authorizationResult: authorizationResult),
            purchaseManager: usesRealPurchases ? StoreKitPurchaseManager() : MockPurchaseManager(),
            userDefaultsStore: InMemoryUserDefaultsStore(),
            reachabilityMonitor: MockNetworkReachabilityMonitor(currentStatus: .satisfied),
            reviewRequester: MockReviewRequester(),
            sharedQuoteStore: NoOpSharedQuoteWriter(),
            bundleInfo: MockBundleInfoProvider(),
            diagnosticReporter: MockDiagnosticReporter(),
            analyticsLogger: MockAnalyticsLogger(),
            featureFlags: MockFeatureFlags(),
            sleeper: MockSleeper()
        )
    }

    private static func productionDependencies() -> Dependencies {
        let container = NSPersistentContainer(name: "QuoteBox")
        container.loadPersistentStores { _, error in
            precondition(error == nil, "Failed to load Core Data store: \(error!)")
        }
        return Dependencies(
            apiClient: QuoteAPIClient(),
            favoritesStore: CoreDataFavoritesStore(container: container),
            reminderScheduler: SystemReminderScheduler(),
            purchaseManager: StoreKitPurchaseManager(),
            userDefaultsStore: SystemUserDefaultsStore(),
            reachabilityMonitor: SystemNetworkReachabilityMonitor(),
            reviewRequester: SystemReviewRequester(),
            sharedQuoteStore: SystemSharedQuoteStore(),
            bundleInfo: SystemBundleInfoProvider(),
            diagnosticReporter: SystemDiagnosticReporter(),
            analyticsLogger: SystemAnalyticsLogger(),
            featureFlags: SystemFeatureFlags(),
            sleeper: SystemSleeper()
        )
    }

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let dependencies = Self.makeDependencies(for: arguments)

        store = QuoteStore(
            apiClient: dependencies.apiClient,
            favoritesStore: dependencies.favoritesStore,
            reminderScheduler: dependencies.reminderScheduler,
            reachabilityMonitor: dependencies.reachabilityMonitor,
            sharedQuoteStore: dependencies.sharedQuoteStore,
            analyticsLogger: dependencies.analyticsLogger,
            featureFlags: dependencies.featureFlags,
            sleeper: dependencies.sleeper
        )
        tipJarStore = TipJarStore(
            purchaseManager: dependencies.purchaseManager,
            analyticsLogger: dependencies.analyticsLogger
        )
        // Under --mock-*, userDefaultsStore is a fresh InMemoryUserDefaultsStore
        // per launch, so this is always 1 - keeping the Debug tab's Launch Count
        // deterministic for QuoteBoxUITests instead of drifting with however many
        // times a real device has been launched. --launch-count <n> overrides
        // that directly (launchCount becomes exactly n for this launch), so a UI
        // test can force a specific value deterministically to reach the
        // review-request threshold without relying on real persisted state.
        if let index = arguments.firstIndex(of: "--launch-count"),
           arguments.indices.contains(index + 1),
           let forcedLaunchCount = Int(arguments[index + 1]) {
            launchCount = forcedLaunchCount
        } else {
            launchCount = dependencies.userDefaultsStore.integer(for: "launchCount") + 1
        }
        dependencies.userDefaultsStore.setInteger(launchCount, for: "launchCount")

        didRequestReviewThisLaunch = launchCount == Self.reviewRequestThreshold
        if didRequestReviewThisLaunch {
            dependencies.reviewRequester.requestReview()
        }

        appVersionString = "\(dependencies.bundleInfo.appVersion) (\(dependencies.bundleInfo.buildNumber))"
        dependencies.diagnosticReporter.startReporting()
        didStartDiagnosticReportingThisLaunch = true

        let launchURL = DeepLinkSource.url(from: arguments) ?? UniversalLinkSource.url(from: arguments)
        _route = State(initialValue: launchURL.flatMap(QuoteBoxRoute.init(url:)))
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                store: store,
                tipJarStore: tipJarStore,
                launchCount: launchCount,
                didRequestReviewThisLaunch: didRequestReviewThisLaunch,
                appVersionString: appVersionString,
                didStartDiagnosticReportingThisLaunch: didStartDiagnosticReportingThisLaunch,
                route: $route
            )
                .onOpenURL { url in
                    route = QuoteBoxRoute(url: url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    route = activity.webpageURL.flatMap(QuoteBoxRoute.init(url:))
                }
        }
    }
}
