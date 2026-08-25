import XCTest
import AnalyticsLogging
import AsyncSleeping
import FeatureFlagging
import TimeControl
import LocalNotifications
@testable import QuoteBox

@MainActor
final class QuoteStoreTests: XCTestCase {
    func testFetchNewQuoteSuccessUpdatesState() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore()
        )

        await store.fetchNewQuote()

        XCTAssertEqual(store.state, .loaded(quote))
    }

    // testFetchNewQuoteFailureUpdatesState (originally .failure(.requestFailed)) is
    // superseded by testFetchNewQuoteDoesNotRetryNonTransientDecodingFailure and
    // testFetchNewQuoteExhaustsRetriesAndSurfacesErrorAfterMaxAttempts below, now
    // that .requestFailed retries with backoff instead of erroring immediately.

    func testToggleFavoriteAddsAndRemovesCurrentQuote() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let favoritesStore = InMemoryFavoritesStore()
        let store = QuoteStore(apiClient: MockQuoteAPIClient(mode: .success(quote)), favoritesStore: favoritesStore)
        await store.fetchNewQuote()

        XCTAssertFalse(store.isCurrentQuoteFavorited)

        store.toggleFavoriteForCurrentQuote()
        XCTAssertTrue(store.isCurrentQuoteFavorited)
        XCTAssertEqual(favoritesStore.favorites, [quote])

        store.toggleFavoriteForCurrentQuote()
        XCTAssertFalse(store.isCurrentQuoteFavorited)
        XCTAssertEqual(favoritesStore.favorites, [])
    }

    func testFavoritesLoadedFromStoreOnInit() {
        let quote = Quote(id: 1, quote: "Seed", author: "Seed Author")
        let favoritesStore = InMemoryFavoritesStore(seed: [quote])
        let store = QuoteStore(apiClient: MockQuoteAPIClient(mode: .success(quote)), favoritesStore: favoritesStore)

        XCTAssertEqual(store.favorites, [quote])
    }

    func testCanFetchNewQuoteRespectsCooldown() async {
        let dateProvider = TestDateProvider(currentDate: Date(timeIntervalSince1970: 0))
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            dateProvider: dateProvider
        )

        XCTAssertTrue(store.canFetchNewQuote)

        await store.fetchNewQuote()
        XCTAssertFalse(store.canFetchNewQuote)

        dateProvider.currentDate.addTimeInterval(QuoteStore.fetchCooldown - 0.1)
        XCTAssertFalse(store.canFetchNewQuote)

        dateProvider.currentDate.addTimeInterval(0.1)
        XCTAssertTrue(store.canFetchNewQuote)
    }

    func testFetchNewQuoteNoOpsWithinCooldown() async {
        let dateProvider = TestDateProvider(currentDate: Date(timeIntervalSince1970: 0))
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            dateProvider: dateProvider
        )

        await store.fetchNewQuote()
        XCTAssertEqual(store.state, .loaded(quote))

        await store.fetchNewQuote()
        XCTAssertEqual(store.state, .loaded(quote))
        XCTAssertFalse(store.canFetchNewQuote)
    }

    func testToggleDailyReminderOnWhenAuthorized() async {
        let scheduler = MockReminderScheduler(authorizationResult: .authorized)
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            reminderScheduler: scheduler
        )

        await store.toggleDailyReminder()

        XCTAssertEqual(store.reminderState, .scheduled)
        XCTAssertEqual(scheduler.scheduledReminder?.hour, QuoteStore.reminderHour)
        XCTAssertEqual(scheduler.scheduledReminder?.minute, QuoteStore.reminderMinute)
    }

    func testToggleDailyReminderShowsDeniedPermissionWhenNotAuthorized() async {
        let scheduler = MockReminderScheduler(authorizationResult: .denied)
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            reminderScheduler: scheduler
        )

        await store.toggleDailyReminder()

        XCTAssertEqual(store.reminderState, .deniedPermission)
        XCTAssertNil(scheduler.scheduledReminder)
    }

    func testToggleDailyReminderOffCancelsExistingReminder() async {
        let scheduler = MockReminderScheduler(authorizationResult: .authorized)
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            reminderScheduler: scheduler
        )
        await store.toggleDailyReminder()
        XCTAssertEqual(store.reminderState, .scheduled)

        await store.toggleDailyReminder()

        XCTAssertEqual(store.reminderState, .off)
        XCTAssertTrue(scheduler.didCancel)
    }

    func testToggleFavoriteLogsAnalyticsEventOnFavorite() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let logger = MockAnalyticsLogger()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            analyticsLogger: logger
        )
        await store.fetchNewQuote()

        store.toggleFavoriteForCurrentQuote()

        XCTAssertEqual(logger.loggedEvents, [LoggedEvent(event: "quote_favorited", parameters: ["quoteID": "1"])])
    }

    func testToggleFavoriteDoesNotLogAnalyticsEventOnUnfavorite() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let logger = MockAnalyticsLogger()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            analyticsLogger: logger
        )
        await store.fetchNewQuote()
        store.toggleFavoriteForCurrentQuote()

        store.toggleFavoriteForCurrentQuote()

        XCTAssertEqual(logger.loggedEvents.count, 1)
    }

    func testFetchNewQuoteLogsNewQuoteFetchedEventOnSuccess() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let logger = MockAnalyticsLogger()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            analyticsLogger: logger
        )

        await store.fetchNewQuote()

        XCTAssertEqual(logger.loggedEvents, [LoggedEvent(event: "new_quote_fetched", parameters: ["quoteID": "1"])])
    }

    func testUsesNewQuoteLayoutReflectsEnabledFlag() {
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            featureFlags: MockFeatureFlags(overrides: ["newQuoteLayout": true])
        )

        XCTAssertTrue(store.usesNewQuoteLayout)
    }

    func testUsesNewQuoteLayoutDefaultsFalseWhenFlagUnset() {
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            featureFlags: MockFeatureFlags()
        )

        XCTAssertFalse(store.usesNewQuoteLayout)
    }

    func testFetchNewQuoteRetriesOnTransientFailureThenSucceeds() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let sleeper = MockSleeper()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .failThenSucceed(failures: 2, then: quote)),
            favoritesStore: InMemoryFavoritesStore(),
            sleeper: sleeper
        )

        await store.fetchNewQuote()

        XCTAssertEqual(store.state, .loaded(quote))
        XCTAssertEqual(sleeper.requestedDurations, QuoteStore.retryDelays)
    }

    func testFetchNewQuoteExhaustsRetriesAndSurfacesErrorAfterMaxAttempts() async {
        let sleeper = MockSleeper()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .failure(.requestFailed)),
            favoritesStore: InMemoryFavoritesStore(),
            sleeper: sleeper
        )

        await store.fetchNewQuote()

        XCTAssertEqual(store.state, .error(APIError.requestFailed.errorDescription!))
        XCTAssertEqual(sleeper.requestedDurations.count, QuoteStore.retryDelays.count)
    }

    func testFetchNewQuoteDoesNotRetryNonTransientDecodingFailure() async {
        let sleeper = MockSleeper()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .failure(.decodingFailed)),
            favoritesStore: InMemoryFavoritesStore(),
            sleeper: sleeper
        )

        await store.fetchNewQuote()

        XCTAssertEqual(store.state, .error(APIError.decodingFailed.errorDescription!))
        XCTAssertTrue(sleeper.requestedDurations.isEmpty)
    }
}
