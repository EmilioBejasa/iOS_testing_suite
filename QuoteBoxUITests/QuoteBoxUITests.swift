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

    /// Whether `toggleFavoriteForCurrentQuote()` actually skips the haptic
    /// call under `--mock-voiceover-running` isn't observable through the
    /// accessibility tree (haptics have no visible/inspectable effect) - that
    /// behavior is unit-tested directly in `QuoteStoreFeatureFlagTests.swift`.
    /// This proves the launch-argument wiring itself resolves end-to-end:
    /// `--mock-voiceover-running` reaches `MockAccessibilityStateProvider`
    /// (surfaced generically on the Debug tab's launch-arguments list, the
    /// same way every other `--mock-*` argument already is), and favoriting
    /// still completes normally rather than crashing or hanging.
    func testFavoritingWithVoiceOverRunningArgumentDoesNotCrash() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success", "--mock-voiceover-running"])
        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        app.tab("Debug").tap()
        XCTAssertTrue(app.element("debugOverlay.list").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["--mock-voiceover-running"].exists)

        app.tab("Quote").tap()
        app.element("quote.favoriteButton").tap()

        app.tab("Favorites").tap()
        XCTAssertTrue(app.element("favorites.list").waitForExistence(timeout: 5))
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
        let app = XCUIApplication().launched(
            withArguments: ["--mock-success", "--universal-link", "https://quotebox.qa/favorites"]
        )

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
        // Known residual flake: .exists and .isEnabled are two separate
        // accessibility-tree round trips, so a transition landing in between
        // them can still throw despite this ordering - a 15s timeout gives the
        // real Product.purchase() round trip (the more common cause of a slow
        // resolve) enough room, but doesn't eliminate that narrower race.
        XCTAssertTrue(waitUntil(timeout: 15) {
            let button = app.element("tipJar.button")
            return app.element("tipJar.thankYou").exists || (button.exists && !button.isEnabled)
        })
        XCTAssertFalse(app.element("tipJar.unavailable").exists)
        try auditIgnoringKnownFalsePositives(app)
    }

    /// Same shape and reasoning as testTipJarPurchaseResolvesAgainstWiredStoreKitConfiguration,
    /// for the "Become a Supporter" subscription product instead of the one-time
    /// tip: `--real-purchases` drives an actual `Product.purchase()` call against
    /// the local StoreKit configuration, and this stops short of the system
    /// purchase-confirmation sheet for the same reason (owned by a process outside
    /// the app's own accessibility tree).
    ///
    /// Unlike the Tip Jar's `state`, `supporterState` is re-checked for real
    /// entitlement on every launch (QuoteView's `.task` calls
    /// `refreshSupporterStatus()`), so a subscription already active from a
    /// prior run against the same local StoreKit test session can mean
    /// `supporter.thankYou` is already showing before this test taps anything -
    /// that still proves the product resolved against the wired configuration,
    /// so it's treated as success rather than skipped.
    func testSupporterSubscriptionResolvesAgainstWiredStoreKitConfiguration() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success", "--real-purchases"])
        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        XCTAssertTrue(waitUntil(timeout: 5) {
            app.element("supporter.button").exists || app.element("supporter.thankYou").exists
        })

        if app.element("supporter.button").exists {
            app.element("supporter.button").tap()

            // Same .exists-before-.isEnabled ordering, and same residual race,
            // as the Tip Jar test above - see its comment for the caveat.
            XCTAssertTrue(waitUntil(timeout: 15) {
                let button = app.element("supporter.button")
                return app.element("supporter.thankYou").exists || (button.exists && !button.isEnabled)
            })
        }
        XCTAssertFalse(app.element("supporter.unavailable").exists)
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
        // MockBundleInfoProvider defaults to "1.0"/"1" under --mock-*.
        XCTAssertTrue(app.staticTexts["Version"].exists)
        XCTAssertTrue(app.staticTexts["1.0 (1)"].exists)
        // diagnosticReporter.startReporting() always fires once per launch.
        XCTAssertTrue(app.staticTexts["Diagnostic Reporting Started"].exists)
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

    /// Same "no pass/fail assertion" reasoning as testAppLaunchPerformance,
    /// applied to memory/CPU instead of launch time - see
    /// measureMemoryAndCPU's doc comment in UITestHelpers. Repeatedly tapping
    /// "New Quote" exercises QuoteStore's fetch-and-replace cycle (network
    /// stub round trip + view re-render) enough times to be worth profiling,
    /// unlike a single tap.
    func testFetchingNewQuotesRepeatedlyPerformance() {
        let app = XCUIApplication().launched(withArguments: ["--mock-success"])
        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        measureMemoryAndCPU {
            for _ in 0..<5 {
                app.element("quote.newButton").tap()
            }
        }
    }

    /// Exploratory: tests the theory that a same-process copy-then-read (the
    /// app reading clipboard content it just wrote itself, inside its own
    /// bundle identity) is exempt from iOS 16+'s cross-app paste-permission
    /// alert - unlike ClipboardProvidingTests's bare-XCTest-bundle round trip,
    /// which hangs indefinitely (CONTRIBUTING.md's Troubleshooting table). If
    /// this theory is wrong and the alert still appears, the
    /// addUIInterruptionMonitor below dismisses it so this test fails on a
    /// normal, bounded assertion instead of consuming this job's full timeout
    /// the way the earlier attempt did - in that case, the existing skip for
    /// testSystemProviderRoundTripsAgainstRealPasteboard stays in place and
    /// this becomes a documented "tried X, still blocked" result, not a
    /// silent revert.
    func testDebugTabShowsRealClipboardRoundTrip() throws {
        let pasteAlertMonitor = addUIInterruptionMonitor(withDescription: "Paste permission alert") { alert in
            if alert.buttons["Allow Paste"].exists {
                alert.buttons["Allow Paste"].tap()
                return true
            }
            if alert.buttons["Don't Allow"].exists {
                alert.buttons["Don't Allow"].tap()
                return true
            }
            return false
        }
        defer { removeUIInterruptionMonitor(pasteAlertMonitor) }

        let app = XCUIApplication().launched(withArguments: ["--mock-success", "--real-clipboard"])
        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        // The copy/read round trip itself runs in RootView's init, at launch -
        // before this test issues any query - so the waitForExistence calls
        // above and below already give XCTest's interruption-monitor check
        // several chances to catch an alert, with no extra gesture needed.
        app.tab("Debug").tap()
        XCTAssertTrue(app.element("debugOverlay.list").waitForExistence(timeout: 5))
        // Audited here, before scrolling - same stable, unscrolled state
        // testDebugTabShowsLaunchArgumentsAndAppState already audits cleanly.
        // Auditing mid-scroll (tried first) surfaced a "Text clipped" false
        // positive on iPhone SE from a row transiently at the screen edge,
        // unrelated to this row's own content.
        try auditIgnoringKnownFalsePositives(app)

        // The Clipboard section is the last one added to the Debug list and
        // can sit below the fold on a smaller screen (iPhone SE) - scroll it
        // into view rather than relying on it already being visible.
        app.element("debugOverlay.list").swipeUp()
        XCTAssertTrue(app.staticTexts["Round Trip"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["clip-ok"].exists)
    }

    /// Proves `SystemReminderScheduler` constructs and its one non-prompting
    /// method (`cancelDailyReminder()`) runs cleanly inside a real host app
    /// bundle - the crash `CONTRIBUTING.md`'s Troubleshooting table documents
    /// for the bare-bundle case (`SystemReminderScheduler`'s default `center`
    /// argument eagerly evaluates `UNUserNotificationCenter.current()`, which
    /// needs `bundleProxyForCurrentProcess`). Deliberately doesn't touch
    /// `requestAuthorization()`/`scheduleDailyReminder()` - see the doc
    /// comment on `--real-notifications` in `RootView.swift` for why that
    /// half of the real path stays untested.
    func testDebugTabShowsRealNotificationsSchedulerConstructsWithoutCrashing() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success", "--real-notifications"])
        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        app.tab("Debug").tap()
        XCTAssertTrue(app.element("debugOverlay.list").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)

        app.element("debugOverlay.list").swipeUp()
        XCTAssertTrue(app.staticTexts["Cancel Call"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["ok"].exists)
    }

    /// Proves `SystemDiagnosticReporter` constructs and both
    /// `startReporting()`/`stopReporting()` run cleanly inside a real host
    /// app bundle - see the doc comment on `--real-diagnostics` in
    /// `RootView.swift` for why this is a genuine same-process round trip
    /// rather than a no-op.
    func testDebugTabShowsRealDiagnosticsStartStopRoundTrip() throws {
        let app = XCUIApplication().launched(withArguments: ["--mock-success", "--real-diagnostics"])
        XCTAssertTrue(app.element("quote.text").waitForExistence(timeout: 5))

        app.tab("Debug").tap()
        XCTAssertTrue(app.element("debugOverlay.list").waitForExistence(timeout: 5))
        try auditIgnoringKnownFalsePositives(app)

        app.element("debugOverlay.list").swipeUp()
        XCTAssertTrue(app.staticTexts["Start/Stop Call"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["ok"].exists)
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
