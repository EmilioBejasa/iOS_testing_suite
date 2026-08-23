import Foundation
import Network
import Observation
import TimeControl
import LocalNotifications
import NetworkReachabilityMonitoring

@Observable
@MainActor
final class QuoteStore {
    enum State: Equatable {
        case idle
        case loading
        case loaded(Quote)
        case error(String)
    }

    enum ReminderState: Equatable {
        case off
        case scheduled
        case deniedPermission
    }

    static let fetchCooldown: TimeInterval = 1
    static let reminderHour = 9
    static let reminderMinute = 0

    private(set) var state: State = .idle
    private(set) var favorites: [Quote]
    private(set) var reminderState: ReminderState = .off
    private(set) var networkStatus: NWPath.Status

    private let apiClient: QuoteAPIClientProtocol
    private let favoritesStore: FavoritesStoring
    private let dateProvider: DateProviding
    private let reminderScheduler: ReminderScheduling
    private let reachabilityMonitor: NetworkReachabilityMonitoring
    private let sharedQuoteStore: SharedQuoteWriting
    private var lastFetchedAt: Date?

    init(
        apiClient: QuoteAPIClientProtocol,
        favoritesStore: FavoritesStoring,
        dateProvider: DateProviding = SystemDateProvider(),
        reminderScheduler: ReminderScheduling = SystemReminderScheduler(),
        reachabilityMonitor: NetworkReachabilityMonitoring = SystemNetworkReachabilityMonitor(),
        sharedQuoteStore: SharedQuoteWriting = SystemSharedQuoteStore()
    ) {
        self.apiClient = apiClient
        self.favoritesStore = favoritesStore
        self.dateProvider = dateProvider
        self.reminderScheduler = reminderScheduler
        self.reachabilityMonitor = reachabilityMonitor
        self.sharedQuoteStore = sharedQuoteStore
        self.favorites = favoritesStore.loadFavorites()
        self.networkStatus = reachabilityMonitor.currentStatus
        reachabilityMonitor.startMonitoring { [weak self] status in
            Task { @MainActor in
                self?.networkStatus = status
            }
        }
    }

    var isCurrentQuoteFavorited: Bool {
        guard case .loaded(let quote) = state else { return false }
        return favorites.contains(quote)
    }

    /// Prevents double-tap spam on "New Quote": false for `fetchCooldown` seconds
    /// after a fetch starts.
    var canFetchNewQuote: Bool {
        guard let lastFetchedAt else { return true }
        return dateProvider.now().timeIntervalSince(lastFetchedAt) >= Self.fetchCooldown
    }

    func fetchNewQuote() async {
        guard canFetchNewQuote else { return }
        lastFetchedAt = dateProvider.now()
        state = .loading
        do {
            let quote = try await apiClient.fetchRandomQuote()
            state = .loaded(quote)
            sharedQuoteStore.save(quote)
        } catch {
            state = .error((error as? LocalizedError)?.errorDescription ?? "Something went wrong.")
        }
    }

    func toggleFavoriteForCurrentQuote() {
        guard case .loaded(let quote) = state else { return }
        if let index = favorites.firstIndex(of: quote) {
            favorites.remove(at: index)
        } else {
            favorites.append(quote)
        }
        favoritesStore.save(favorites)
    }

    func toggleDailyReminder() async {
        if reminderState == .scheduled {
            reminderScheduler.cancelDailyReminder()
            reminderState = .off
            return
        }

        guard await reminderScheduler.requestAuthorization() == .authorized else {
            reminderState = .deniedPermission
            return
        }

        do {
            try await reminderScheduler.scheduleDailyReminder(hour: Self.reminderHour, minute: Self.reminderMinute)
            reminderState = .scheduled
        } catch {
            reminderState = .off
        }
    }
}
