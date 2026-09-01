import XCTest
import AnalyticsLogging
import AsyncSleeping
import BundleInfoProviding
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

        await store.toggleFavoriteForCurrentQuote()
        XCTAssertTrue(store.isCurrentQuoteFavorited)
        XCTAssertEqual(favoritesStore.favorites, [quote])

        await store.toggleFavoriteForCurrentQuote()
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

/// Split out of `QuoteStoreTests` to keep each type comfortably under
/// SwiftLint's `type_body_length` limit (the branch already hit this
/// category of lint issue once, for `function_body_length` in `889f39a`) -
/// groups every test that asserts on `AnalyticsLogging` output specifically.
@MainActor
final class QuoteStoreAnalyticsTests: XCTestCase {
    func testToggleFavoriteLogsAnalyticsEventOnFavorite() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let logger = MockAnalyticsLogger()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            analyticsLogger: logger,
            bundleInfo: MockBundleInfoProvider()
        )
        await store.fetchNewQuote()

        await store.toggleFavoriteForCurrentQuote()

        // fetchNewQuote() above already logged its own "new_quote_fetched"
        // event (see testFetchNewQuoteLogsNewQuoteFetchedEventOnSuccess), so
        // this filters for the event under test rather than asserting the
        // full log, keeping this test's intent independent of that one.
        let favoritedEvents = logger.loggedEvents.filter { $0.event == "quote_favorited" }
        XCTAssertEqual(
            favoritedEvents,
            [LoggedEvent(event: "quote_favorited", parameters: ["quoteID": "1", "appVersion": "1.0"])]
        )
    }

    func testToggleFavoriteLogsAnalyticsEventOnUnfavorite() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let logger = MockAnalyticsLogger()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            analyticsLogger: logger,
            bundleInfo: MockBundleInfoProvider()
        )
        await store.fetchNewQuote()
        await store.toggleFavoriteForCurrentQuote()

        await store.toggleFavoriteForCurrentQuote()

        // Same filtering as testToggleFavoriteLogsAnalyticsEventOnFavorite -
        // only "quote_favorited" fired once, not again on unfavorite.
        let favoritedEvents = logger.loggedEvents.filter { $0.event == "quote_favorited" }
        XCTAssertEqual(favoritedEvents.count, 1)

        let unfavoritedEvents = logger.loggedEvents.filter { $0.event == "quote_unfavorited" }
        XCTAssertEqual(
            unfavoritedEvents,
            [LoggedEvent(event: "quote_unfavorited", parameters: ["quoteID": "1", "appVersion": "1.0"])]
        )
    }

    func testFetchNewQuoteLogsNewQuoteFetchedEventOnSuccess() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let logger = MockAnalyticsLogger()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            analyticsLogger: logger,
            bundleInfo: MockBundleInfoProvider()
        )

        await store.fetchNewQuote()

        XCTAssertEqual(
            logger.loggedEvents,
            [LoggedEvent(event: "new_quote_fetched", parameters: ["quoteID": "1", "appVersion": "1.0"])]
        )
    }

    func testFetchNewQuoteLogsInjectedAppVersionAsParameter() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let logger = MockAnalyticsLogger()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            analyticsLogger: logger,
            bundleInfo: MockBundleInfoProvider(appVersion: "2.0", buildNumber: "42")
        )

        await store.fetchNewQuote()

        XCTAssertEqual(logger.loggedEvents.first?.parameters["appVersion"], "2.0")
    }

    func testToggleDailyReminderLogsAnalyticsEventWhenEnabled() async {
        let logger = MockAnalyticsLogger()
        let scheduler = MockReminderScheduler(authorizationResult: .authorized)
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            reminderScheduler: scheduler,
            analyticsLogger: logger,
            bundleInfo: MockBundleInfoProvider()
        )

        await store.toggleDailyReminder()

        XCTAssertEqual(
            logger.loggedEvents,
            [LoggedEvent(event: "daily_reminder_enabled", parameters: ["appVersion": "1.0"])]
        )
    }

    func testToggleDailyReminderLogsAnalyticsEventWhenDisabled() async {
        let logger = MockAnalyticsLogger()
        let scheduler = MockReminderScheduler(authorizationResult: .authorized)
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            reminderScheduler: scheduler,
            analyticsLogger: logger,
            bundleInfo: MockBundleInfoProvider()
        )
        await store.toggleDailyReminder()

        await store.toggleDailyReminder()

        let disabledEvents = logger.loggedEvents.filter { $0.event == "daily_reminder_disabled" }
        XCTAssertEqual(
            disabledEvents,
            [LoggedEvent(event: "daily_reminder_disabled", parameters: ["appVersion": "1.0"])]
        )
    }

    func testToggleDailyReminderDoesNotLogAnalyticsEventWhenPermissionDenied() async {
        let logger = MockAnalyticsLogger()
        let scheduler = MockReminderScheduler(authorizationResult: .denied)
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            reminderScheduler: scheduler,
            analyticsLogger: logger,
            bundleInfo: MockBundleInfoProvider()
        )

        await store.toggleDailyReminder()

        XCTAssertTrue(logger.loggedEvents.isEmpty)
    }
}
