import CoreData
import DeepLinkTesting
import LocalNotifications
import PurchaseSupport
import SwiftUI
import UserDefaultsStore

@main
struct QuoteBoxApp: App {
    private let store: QuoteStore
    private let tipJarStore: TipJarStore
    private let launchCount: Int
    @State private var route: QuoteBoxRoute?

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let apiClient: QuoteAPIClientProtocol
        let favoritesStore: FavoritesStoring
        let reminderScheduler: ReminderScheduling
        let purchaseManager: PurchaseManaging
        let userDefaultsStore: UserDefaultsStoring

        if arguments.contains("--mock-error") {
            apiClient = MockQuoteAPIClient(mode: .failure(.requestFailed))
            favoritesStore = InMemoryFavoritesStore()
            reminderScheduler = MockReminderScheduler(authorizationResult: .authorized)
            purchaseManager = MockPurchaseManager()
            userDefaultsStore = InMemoryUserDefaultsStore()
        } else if arguments.contains("--mock-success") {
            apiClient = MockQuoteAPIClient(mode: .success(MockQuoteAPIClient.defaultQuote))
            favoritesStore = InMemoryFavoritesStore()
            let authorizationResult: AuthorizationStatus = arguments.contains("--mock-notifications-denied") ? .denied : .authorized
            reminderScheduler = MockReminderScheduler(authorizationResult: authorizationResult)
            purchaseManager = arguments.contains("--real-purchases") ? StoreKitPurchaseManager() : MockPurchaseManager()
            userDefaultsStore = InMemoryUserDefaultsStore()
        } else {
            apiClient = QuoteAPIClient()
            let container = NSPersistentContainer(name: "QuoteBox")
            container.loadPersistentStores { _, error in
                precondition(error == nil, "Failed to load Core Data store: \(error!)")
            }
            favoritesStore = CoreDataFavoritesStore(container: container)
            reminderScheduler = SystemReminderScheduler()
            purchaseManager = StoreKitPurchaseManager()
            userDefaultsStore = SystemUserDefaultsStore()
        }

        store = QuoteStore(apiClient: apiClient, favoritesStore: favoritesStore, reminderScheduler: reminderScheduler)
        tipJarStore = TipJarStore(purchaseManager: purchaseManager)
        // Under --mock-*, userDefaultsStore is a fresh InMemoryUserDefaultsStore
        // per launch, so this is always 1 - keeping the Debug tab's Launch Count
        // deterministic for QuoteBoxUITests instead of drifting with however many
        // times a real device has been launched.
        launchCount = userDefaultsStore.integer(for: "launchCount") + 1
        userDefaultsStore.setInteger(launchCount, for: "launchCount")
        let launchURL = DeepLinkSource.url(from: arguments) ?? UniversalLinkSource.url(from: arguments)
        _route = State(initialValue: launchURL.flatMap(QuoteBoxRoute.init(url:)))
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, tipJarStore: tipJarStore, launchCount: launchCount, route: $route)
                .onOpenURL { url in
                    route = QuoteBoxRoute(url: url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    route = activity.webpageURL.flatMap(QuoteBoxRoute.init(url:))
                }
        }
    }
}
