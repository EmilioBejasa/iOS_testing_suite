import XCTest
import UITestHelpers

final class QuoteBoxUITests: XCTestCase {
    func testMockSuccessShowsQuoteAndCanFavoriteIt() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))
        XCTAssertTrue(app.element("quote.author").exists)
        try auditIgnoringKnownFalsePositives(app)

        app.element("quote.favoriteButton").tap()

        app.tab("Favorites").tap()
        XCTAssertTrue(app.element("favorites.list").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)
    }

    func testMockErrorShowsErrorMessage() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-error"])

        XCTAssertTrue(app.element("quote.errorMessage").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)
    }

    func testFavoritesTabStartsEmptyWithoutFavoriting() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        app.tab("Favorites").tap()
        XCTAssertTrue(app.element("favorites.empty").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)
    }

    func testEnablingDailyReminderTurnsToggleOn() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))
        XCTAssertEqual(app.element("quote.reminderToggle").value as? String, "0")

        app.element("quote.reminderToggle").tap()

        XCTAssertTrue(waitUntil(timeout: 5) { app.element("quote.reminderToggle").value as? String == "1" })
        try auditIgnoringKnownFalsePositives(app)
    }

    func testDeniedNotificationPermissionShowsMessage() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success", "--mock-notifications-denied"])

        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))
        app.element("quote.reminderToggle").tap()

        XCTAssertTrue(app.element("quote.reminderDeniedMessage").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)
    }

    func testDeepLinkToFavoritesOpensFavoritesTab() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success", "--deep-link", "quotebox://favorites"])

        XCTAssertTrue(app.element("favorites.empty").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)
    }

    /// Same technique as testDeepLinkToFavoritesOpensFavoritesTab, exercising
    /// UniversalLinkSource's --universal-link launch argument instead of
    /// --deep-link, and QuoteBoxRoute's second init?(url:) match arm for the
    /// https://quotebox.qa/favorites shape a real Universal Link would use.
    func testUniversalLinkToFavoritesOpensFavoritesTab() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success", "--universal-link", "https://quotebox.qa/favorites"])

        XCTAssertTrue(app.element("favorites.empty").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)
    }

    /// `--real-purchases` swaps in the real `StoreKitPurchaseManager` (everything
    /// else stays mocked/deterministic), so tapping Tip Jar drives an actual
    /// `Product.purchase()` call against the local StoreKit configuration the
    /// `QuoteBox` scheme's Run action is wired to (`project.yml`'s
    /// `storeKitConfiguration`). Reaching `.purchasing` (button disables) or
    /// `.purchased` (already owned from a prior run) both prove the product
    /// resolved against that configuration instead of a real, unreachable App
    /// Store — only `.failed` indicates the config isn't wired. This deliberately
    /// stops there: the system purchase-confirmation sheet itself is owned by a
    /// process outside the app's own accessibility tree, so reliably tapping
    /// through it means resorting to raw coordinate taps — the same class of
    /// fragile, OS-version-dependent hack this kit avoids everywhere else a
    /// system-owned dialog is involved (see `LocationAuthorization`'s
    /// `.notDetermined` avoidance and `DeepLinkTesting`'s avoidance of the native
    /// "Open in App" confirmation).
    func testTipJarPurchaseResolvesAgainstWiredStoreKitConfiguration() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success", "--real-purchases"])
        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        app.element("tipJar.button").tap()

        // Query .exists before .isEnabled - once state moves to .failed, the
        // button leaves the hierarchy entirely (QuoteView renders tipJar.unavailable
        // instead), and querying .isEnabled on an element that no longer exists
        // throws a hard XCUITest snapshot error rather than returning false.
        XCTAssertTrue(waitUntil(timeout: 5) {
            let button = app.element("tipJar.button")
            return app.element("tipJar.thankYou").exists || (button.exists && !button.isEnabled)
        })
        XCTAssertFalse(app.element("tipJar.unavailable").exists)
        try auditIgnoringKnownFalsePositives(app)
    }

    /// The Debug tab only exists in Debug builds (`#if DEBUG` in `RootView`), which
    /// is what every scheme in `project.yml` builds with by default — including the
    /// one CI's `xcodebuild test` runs against — so it's expected to be present here.
    func testDebugTabShowsLaunchArgumentsAndAppState() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])
        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        app.tab("Debug").tap()

        XCTAssertTrue(app.element("debugOverlay.list").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["--mock-success"].exists)
        XCTAssertTrue(app.staticTexts["Tip Jar"].exists)
        // Under --mock-*, QuoteBoxApp uses a fresh InMemoryUserDefaultsStore per
        // launch, so this is deterministically 1 rather than drifting with however
        // many times the Simulator has launched the app.
        XCTAssertTrue(app.staticTexts["1"].exists)
        // MockNetworkReachabilityMonitor always reports .satisfied under --mock-*.
        XCTAssertTrue(app.staticTexts["satisfied"].exists)
        // launchCount is 1 here, below reviewRequestThreshold (3).
        XCTAssertTrue(app.staticTexts["false"].exists)
        try auditIgnoringKnownFalsePositives(app)
    }

    /// --launch-count 3 forces launchCount directly to
    /// QuoteBoxApp.reviewRequestThreshold, deterministically reaching the branch
    /// that calls reviewRequester.requestReview() without depending on real
    /// persisted launch history.
    func testReviewRequestedAtLaunchCountThreshold() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success", "--launch-count", "3"])
        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        app.tab("Debug").tap()

        XCTAssertTrue(app.element("debugOverlay.list").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["3"].exists)
        XCTAssertTrue(app.staticTexts["true"].exists)
        try auditIgnoringKnownFalsePositives(app)
    }

    /// No pass/fail assertion on duration - see `measureLaunch`'s doc comment in
    /// `UITestHelpers` for why a fixed threshold isn't safe on shared CI hardware.
    /// This exists to get real numbers into the .xcresult that `reusable-test.yml`
    /// already uploads as a CI artifact.
    func testAppLaunchPerformance() {
        measureLaunch(withArguments: ["--mock-success"])
    }

    /// Re-evaluates `condition` (which should re-query fresh each call, e.g. via
    /// `app.element(_:)`) rather than waiting on a single captured `XCUIElement`,
    /// since a snapshot taken before a UI change doesn't reliably live-update.
    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            usleep(100_000)
        }
        return condition()
    }

    /// Two audit types are allow-listed for reasons unrelated to QuoteBox's own
    /// text/color choices, confirmed by diagnostic runs before landing this:
    ///  - `.contrast`: headless CI simulators report a generic "Contrast nearly
    ///    passed... unless font size is larger" finding on every text/button
    ///    element regardless of its actual color (default black text, .secondary
    ///    gray, .borderedProminent's white-on-accent all hit it identically) — a
    ///    known false-positive pattern for this audit type in this environment.
    ///  - `.dynamicType`: only fails on iPad, never on iPhone 16/SE running the
    ///    identical view code, and neither QuoteView nor FavoritesView has any
    ///    .lineLimit/.fixedSize/fixed frame that could truncate text. project.yml
    ///    sets `TARGETED_DEVICE_FAMILY: "1"` (iPhone-only), so on iPad the app runs
    ///    in iPhone-compatibility mode, which has real, documented Dynamic Type
    ///    scaling limitations — not a text-layout bug in this app's views.
    /// Every other audit type (missing labels, hit target size, element detection,
    /// etc.) still fails the test normally.
    private func auditIgnoringKnownFalsePositives(_ app: XCUIApplication) throws {
        try app.auditAccessibility(allowing: { $0.auditType == .contrast || $0.auditType == .dynamicType })
    }
}
