import AnalyticsLogging
import AsyncSleeping
import FeatureFlagging
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
    /// Backoff between retries of a transient `APIError.requestFailed` in
    /// `fetchNewQuote()` - 2 retries (3 attempts total) before surfacing an
    /// error to the UI.
    static let retryDelays: [Duration] = [.seconds(1), .seconds(2)]

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
    private let analyticsLogger: AnalyticsLogging
    private let featureFlags: FeatureFlagging
    private let sleeper: AsyncSleeping
    private var lastFetchedAt: Date?

    init(
        apiClient: QuoteAPIClientProtocol,
        favoritesStore: FavoritesStoring,
        dateProvider: DateProviding = SystemDateProvider(),
        reminderScheduler: ReminderScheduling = SystemReminderScheduler(),
        reachabilityMonitor: NetworkReachabilityMonitoring = SystemNetworkReachabilityMonitor(),
        sharedQuoteStore: SharedQuoteWriting = NoOpSharedQuoteWriter(),
        analyticsLogger: AnalyticsLogging = SystemAnalyticsLogger(),
        featureFlags: FeatureFlagging = SystemFeatureFlags(),
        sleeper: AsyncSleeping = SystemSleeper()
    ) {
        self.apiClient = apiClient
        self.favoritesStore = favoritesStore
        self.dateProvider = dateProvider
        self.reminderScheduler = reminderScheduler
        self.reachabilityMonitor = reachabilityMonitor
        self.sharedQuoteStore = sharedQuoteStore
        self.analyticsLogger = analyticsLogger
        self.featureFlags = featureFlags
        self.sleeper = sleeper
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

    var usesNewQuoteLayout: Bool {
        featureFlags.isEnabled("newQuoteLayout")
    }

    /// Prevents double-tap spam on "New Quote": false for `fetchCooldown` seconds
    /// after a fetch starts.
    var canFetchNewQuote: Bool {
        guard let lastFetchedAt else { return true }
        return dateProvider.now().timeIntervalSince(lastFetchedAt) >= Self.fetchCooldown
    }

    /// Retries a transient `APIError.requestFailed` up to `retryDelays.count`
    /// times, backing off via the injected `sleeper` between attempts, before
    /// surfacing an error to the UI. `.invalidURL`/`.decodingFailed` aren't
    /// transient, so they surface immediately with no retry.
    func fetchNewQuote() async {
        guard canFetchNewQuote else { return }
        lastFetchedAt = dateProvider.now()
        state = .loading

        for attempt in 1...(Self.retryDelays.count + 1) {
            do {
                let quote = try await apiClient.fetchRandomQuote()
                state = .loaded(quote)
                sharedQuoteStore.save(quote)
                analyticsLogger.log(event: "new_quote_fetched", parameters: ["quoteID": "\(quote.id)"])
                return
            } catch {
                let isTransient = (error as? APIError) == .requestFailed
                let hasRetriesLeft = attempt <= Self.retryDelays.count
                if isTransient && hasRetriesLeft {
                    try? await sleeper.sleep(for: Self.retryDelays[attempt - 1])
                    continue
                }
                state = .error((error as? LocalizedError)?.errorDescription ?? "Something went wrong.")
                return
            }
        }
    }

    func toggleFavoriteForCurrentQuote() {
        guard case .loaded(let quote) = state else { return }
        if let index = favorites.firstIndex(of: quote) {
            favorites.remove(at: index)
        } else {
            favorites.append(quote)
            analyticsLogger.log(event: "quote_favorited", parameters: ["quoteID": "\(quote.id)"])
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
