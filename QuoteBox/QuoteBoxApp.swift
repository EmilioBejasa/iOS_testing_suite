import CoreData
import LocalNotifications
import SwiftUI

@main
struct QuoteBoxApp: App {
    private let store: QuoteStore

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let apiClient: QuoteAPIClientProtocol
        let favoritesStore: FavoritesStoring
        let reminderScheduler: ReminderScheduling

        if arguments.contains("--mock-error") {
            apiClient = MockQuoteAPIClient(mode: .failure(.requestFailed))
            favoritesStore = InMemoryFavoritesStore()
            reminderScheduler = MockReminderScheduler(authorizationResult: .authorized)
        } else if arguments.contains("--mock-success") {
            apiClient = MockQuoteAPIClient(mode: .success(MockQuoteAPIClient.defaultQuote))
            favoritesStore = InMemoryFavoritesStore()
            let authorizationResult: AuthorizationStatus = arguments.contains("--mock-notifications-denied") ? .denied : .authorized
            reminderScheduler = MockReminderScheduler(authorizationResult: authorizationResult)
        } else {
            apiClient = QuoteAPIClient()
            let container = NSPersistentContainer(name: "QuoteBox")
            container.loadPersistentStores { _, error in
                precondition(error == nil, "Failed to load Core Data store: \(error!)")
            }
            favoritesStore = CoreDataFavoritesStore(container: container)
            reminderScheduler = SystemReminderScheduler()
        }

        store = QuoteStore(apiClient: apiClient, favoritesStore: favoritesStore, reminderScheduler: reminderScheduler)
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
    }
}
