import CoreData
import DeepLinkTesting
import LocalNotifications
import PurchaseSupport
import SwiftUI

@main
struct QuoteBoxApp: App {
    private let store: QuoteStore
    private let tipJarStore: TipJarStore
    @State private var route: QuoteBoxRoute?

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let apiClient: QuoteAPIClientProtocol
        let favoritesStore: FavoritesStoring
        let reminderScheduler: ReminderScheduling
        let purchaseManager: PurchaseManaging

        if arguments.contains("--mock-error") {
            apiClient = MockQuoteAPIClient(mode: .failure(.requestFailed))
            favoritesStore = InMemoryFavoritesStore()
            reminderScheduler = MockReminderScheduler(authorizationResult: .authorized)
            purchaseManager = MockPurchaseManager()
        } else if arguments.contains("--mock-success") {
            apiClient = MockQuoteAPIClient(mode: .success(MockQuoteAPIClient.defaultQuote))
            favoritesStore = InMemoryFavoritesStore()
            let authorizationResult: AuthorizationStatus = arguments.contains("--mock-notifications-denied") ? .denied : .authorized
            reminderScheduler = MockReminderScheduler(authorizationResult: authorizationResult)
            purchaseManager = arguments.contains("--real-purchases") ? StoreKitPurchaseManager() : MockPurchaseManager()
        } else {
            apiClient = QuoteAPIClient()
            let container = NSPersistentContainer(name: "QuoteBox")
            container.loadPersistentStores { _, error in
                precondition(error == nil, "Failed to load Core Data store: \(error!)")
            }
            favoritesStore = CoreDataFavoritesStore(container: container)
            reminderScheduler = SystemReminderScheduler()
            purchaseManager = StoreKitPurchaseManager()
        }

        store = QuoteStore(apiClient: apiClient, favoritesStore: favoritesStore, reminderScheduler: reminderScheduler)
        tipJarStore = TipJarStore(purchaseManager: purchaseManager)
        _route = State(initialValue: DeepLinkSource.url(from: arguments).flatMap(QuoteBoxRoute.init(url:)))
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, tipJarStore: tipJarStore, route: $route)
                .onOpenURL { url in
                    route = QuoteBoxRoute(url: url)
                }
        }
    }
}
