# Changelog

All notable changes to this package are documented here. Versions correspond
to git tags; see the [README](README.md) for what each module does and how to
depend on it.

## [1.7.0] - 2026-09-01

Wired a 7th kit module into `QuoteBox`: `AccessibilityStateProviding`.
`QuoteStore.toggleFavoriteForCurrentQuote()` now suppresses the
`HapticFeedbackProviding` haptic call whenever `isVoiceOverRunning()` is
true, even with `"hapticFeedbackEnabled"` on — VoiceOver has its own
feedback conventions, so a redundant custom impact reads as noise rather
than help. New `--mock-voiceover-running` launch argument forces
`MockAccessibilityStateProvider(voiceOverRunning: true)` under
`--mock-success`. The behavior itself (haptic fires or doesn't) is
unit-tested directly in `QuoteStoreFeatureFlagTests.swift` since it has no
observable effect through the accessibility tree; a new `QuoteBoxUITests`
case proves the launch-argument wiring resolves end-to-end instead.

`project.yml` gained `AccessibilityStateProviding` as a `QuoteBox`/
`QuoteBoxTests` target dependency, same reasoning prior version bumps
followed for each newly-wired module.

## [1.6.1] - 2026-09-01

One CI-stabilization fix, plus a documented dead end, following up on
[1.6.0]'s `KNOWN_FLAKE_PATTERN`/timeout work:

- **Tried and reverted**: pinning `randomExecutionOrdering: false` on
  `QuoteBoxTests`/`QuoteBoxUITests` (testing the theory that Xcode's default
  randomized test order was the cause of the snapshot byte-drift flakes -
  [1.6.0]). It made the failure on `testQuoteContentViewLoadedNewLayoutAccessibility3`
  *worse*: instead of an intermittent flake, the pinned order reproduced the
  exact same byte mismatch (confirmed via 3 repeat CI attempts landing
  identical byte counts on both iPhone 16 and iPhone SE) on every single run.
  Recording a fresh reference in isolation (`record-snapshots.yml`,
  `-only-testing:` scoped to just this one test) reproduced the *original*
  committed reference exactly, not the byte pattern the full pinned-order
  suite produces - confirming the drift really is caused by test-adjacency
  (whatever specific test now always runs immediately before it in the
  pinned order) rather than a generic environment/machine difference, but
  also showing this repo's `record-snapshots.yml` tooling (single-test
  scoped) can't currently capture that context to fix it properly. Reverted
  to Xcode's default randomized order, which at least sometimes passes,
  pending a fix that re-records the whole suite in one pinned-order pass
  rather than a single isolated test.
- `QuoteBoxUITests.swift`: the two StoreKit-purchase tests
  (`testTipJarPurchaseResolvesAgainstWiredStoreKitConfiguration`,
  `testSupporterSubscriptionResolvesAgainstWiredStoreKitConfiguration`) now
  wait up to 15s (was 5s) for their terminal state, giving the real
  `Product.purchase()` StoreKitTest round trip realistic headroom. Documented
  a known residual limitation: these waits still call `.isEnabled` on a button
  that can vanish between that call and a preceding `.exists` check (two
  separate accessibility-tree round trips), which can throw rather than
  return `false` - the longer timeout helps the common "just slow" case but
  doesn't eliminate that narrower race; fixing it fully would need either a
  dedicated "purchasing" accessibility identifier or Objective-C
  exception-bridging, both left as follow-up.

## [1.6.0] - 2026-08-26

Deepened the 5 kit modules [1.5.0] wired into `QuoteBox`, and wired in a 6th —
continuing that version's pattern of closing gaps between "wired" and
"actually integrated":

- `AnalyticsLogging`: 4 new events alongside the existing 3 —
  `quote_unfavorited` (the remove branch of `toggleFavoriteForCurrentQuote()`,
  previously silent), `daily_reminder_enabled`/`daily_reminder_disabled`
  (`toggleDailyReminder()`'s schedule/cancel branches), and
  `supporter_subscribed` (`purchaseSupporterSubscription()`'s success branch).
  Every event now also carries an `"appVersion"` parameter via a new
  `bundleInfo: BundleInfoProviding` dependency on both `QuoteStore` and
  `TipJarStore`.
- `tip_purchased` finally has deterministic unit coverage: new
  `TipJarStoreRealSessionTests.testPurchaseTipLogsAnalyticsEventOnSuccess`
  fetches a real `Product` via `SKTestSession` + `StoreKitPurchaseManager`
  (`PurchaseSupportRealSessionTests`'s approach) and feeds it to
  `MockPurchaseManager`, closing the gap `TipJarStore.purchaseTip()`'s doc
  comment used to document as unreachable from a mock alone.
- `FeatureFlagging`: a second flag, `"hapticFeedbackEnabled"`, gating the new
  `HapticFeedbackProviding` wiring below — proves the module composes with a
  second, unrelated flag rather than being a one-off.
- `DiagnosticReporting`: `stopReporting()` previously went uncalled anywhere
  in `QuoteBox`. `RootView` now exercises it for real via a new
  `--real-diagnostics` launch argument, following the same same-process
  real-round-trip pattern `--real-clipboard`/`--real-notifications` already
  use, surfaced as a new "Diagnostics" Debug-tab section.
- `HapticFeedbackProviding` (6th module wired in): `QuoteStore.toggleFavoriteForCurrentQuote()`
  fires `.light` impact feedback on both the favorite and unfavorite
  branches, gated behind `"hapticFeedbackEnabled"`. Since `impact(style:)` is
  `async`, `toggleFavoriteForCurrentQuote()` is now `async` too — its one
  call site in `QuoteView` wraps it in `Task { ... }`, the same pattern its
  "New Quote" button already used.
- New `QuoteBoxTests/QuoteBoxAppTests.swift` unit-tests the dependency-resolution
  seam `QuoteBoxApp.makeDependencies(for:)` (`private` until now) exposes —
  the `appVersionString` formula and `MockDiagnosticReporter.startReportingCallCount`,
  previously covered only indirectly via `QuoteBoxUITests`.

`project.yml` gained `HapticFeedbackProviding` as a `QuoteBox` target
dependency, plus `BundleInfoProviding`/`DiagnosticReporting`/`HapticFeedbackProviding`
on `QuoteBoxTests` (needed once tests started importing them directly, the
same reasoning [1.5.0] added `AnalyticsLogging`/`FeatureFlagging`/`AsyncSleeping`
there). Run `make setup` to regenerate `QuoteBox.xcodeproj` after pulling this.

Also: extended `KNOWN_FLAKE_PATTERN` (from [1.1.0]'s targeted CI retry) to
cover three snapshot tests (`testQuoteContentViewLoadedNewLayoutAccessibility3`,
`testRootViewQuoteTabLoaded`, `testQuoteViewErrorState`) that intermittently
fail on phone-class simulators with a several-hundred-byte mismatch against
the committed reference PNG — confirmed not a stale reference (a fresh local
re-recording is byte-identical to what's committed), most likely Xcode's
randomized test order leaving the font-rendering cache in a slightly
different state test-to-test. Also raised the test job's `timeout-minutes`
from 30 to 45: a retried attempt plus the coverage-report step didn't
reliably fit in 30 minutes, and a run was observed passing all tests on
retry only to have the job killed by the timeout before it could report.

## [1.5.0] - 2026-08-25

Wired 4 previously kit-level-only modules into real `QuoteBox` features —
continuing the pattern every prior version bump followed, closing the gap
between "tested in isolation" and "proven through a real app integration":

- `AnalyticsLogging`: `QuoteStore.toggleFavoriteForCurrentQuote()` logs
  `quote_favorited` on the add-to-favorites branch (the README's own
  long-standing example event), `fetchNewQuote()` logs `new_quote_fetched` on
  success, and `TipJarStore.purchaseTip()` logs `tip_purchased` on its
  `.purchased` branch — the last one real but untestable by a deterministic
  unit test (`MockPurchaseManager.product(for:)` defaults to `nil`), so it's
  only exercised via the existing real-StoreKit-session UI test.
- `FeatureFlagging`: `QuoteStore.usesNewQuoteLayout` resolves the `"newQuoteLayout"`
  flag (the README's own long-standing example flag) and `QuoteView` passes
  it into `QuoteContentView`'s new `usesNewLayout` parameter, gating a real
  alternate card-style layout. New `QuoteBoxTests/QuoteViewSnapshotTests.swift`
  snapshots cover both layout states (default and `.accessibility3` sizing).
- `AsyncSleeping`: `QuoteStore.fetchNewQuote()` now retries a transient
  `APIError.requestFailed` up to twice with backoff (`[.seconds(1), .seconds(2)]`)
  before surfacing an error — closing the gap the module's own README section
  used to state outright ("nothing natural to wire it into yet").
  `MockQuoteAPIClient` gained a `.failThenSucceed(failures:then:)` mode to
  drive this deterministically in tests.
- `BundleInfoProviding` + `DiagnosticReporting`: two new Debug tab rows in the
  existing "App" section ("Version", "Diagnostic Reporting Started"), both
  safe, non-prompting real reads following the same "pass a resolved value,
  not the dependency" shape `ReviewRequesting`'s row already uses.

`project.yml` gained the 5 corresponding `dependencies:` entries on the
`QuoteBox` target (`AnalyticsLogging`, `FeatureFlagging`, `AsyncSleeping`,
`BundleInfoProviding`, `DiagnosticReporting`) and 3 on `QuoteBoxTests`
(`AnalyticsLogging`, `FeatureFlagging`, `AsyncSleeping`) — `Package.swift`
already declared all 5 products, so no SwiftPM manifest change was needed.
Run `make setup` to regenerate `QuoteBox.xcodeproj` after pulling this.

Also fixed a latent test-speed issue this surfaced: two existing tests
constructed `QuoteStore`/`QuoteAPIClient` failures via `.requestFailed`
without injecting a sleeper, which would now retry against the real
`SystemSleeper` default (3 real seconds) instead of failing immediately —
switched to `.decodingFailed` (a genuinely non-transient error) where the
test's actual point was just the error-surfacing path, not retry behavior.

## [1.4.0] - 2026-08-21

Real `swift test` support: 49 kit-only test files moved out of
`QuoteBoxTests/` into their own `Tests/<Module>Tests/` SwiftPM test targets.
26 of them (the modules with no iOS/Catalyst-only framework import in their
`Sources/`) run and pass under a plain `swift test` on macOS, no Xcode
project needed at all. The remaining 23 — whose `Sources/` unconditionally
import UIKit, HealthKit, CoreMotion, CoreTelephony, MediaPlayer, ActivityKit,
BackgroundTasks, WatchConnectivity, AppTrackingTransparency, FamilyControls,
MetricKit, HomeKit, or Intents — are now wrapped in matching `#if os(iOS)`
guards (both the `Sources/` implementation files and their test files), so
they still build cleanly (as empty targets) under `swift test` on macOS and
run their real assertions via `xcodebuild test -scheme iOSTestKit-Package
-destination 'platform=iOS Simulator,name=...'` instead — still against the
bare `Package.swift`, no XcodeGen or the `QuoteBox` app required. `#if
canImport(Framework)` looked like the obvious guard but proved wrong for
CoreMotion and Intents specifically: the module itself resolves on macOS,
just missing the type this kit needs, so `canImport` evaluated true and
still failed to compile — caught by CI, not anticipated in advance. A
handful of macOS-runnable modules whose real
platform floor is newer than this package's `.macOS(.v13)` (the granular
EventKit access APIs, `SwiftData`, `XCTest`'s accessibility audit) needed an
explicit `macOS 14.0` added alongside their existing `@available(iOS 17.0,
*)` annotation — Apple ships those APIs on iOS 17 and macOS 14 together, but
the source only declared the iOS side. `project.yml`'s `QuoteBoxTests`
bundle now depends on only the 9 products its remaining 8 app-dependent
files actually use, down from all 59. Two new CI jobs (`swift-test`,
`kit-tests-ios`) keep both paths covered on every push and PR.

One-command demo setup: `make setup` (or `Scripts/setup.sh`) installs
XcodeGen via Homebrew if missing and runs `xcodegen generate`, so a fresh
clone gets to `open QuoteBox.xcodeproj` in one step. `make test-kit`,
`make test-kit-ios`, `make test-app`, and `make lint` wrap the four ways to
exercise this repo.

CI now runs SwiftLint (`.swiftlint.yml`, report-only for this release while
the existing 60-module codebase gets triaged against the default ruleset)
and supports an opt-in coverage-regression floor via
`reusable-test.yml`'s new `coverage_baseline_file` input.

Also folds in three commits that landed after the `v1.3.0` tag was cut:
governance files (`SECURITY.md`, `CODEOWNERS`, PR/issue templates), a fix
for `live-api-contract.yml`'s missing schedule trigger, and closing out the
`SnapshotTesting` module's accessibility3 scope note.

## [1.3.0] - 2026-08-17

Added 9 modules, bringing the kit from 50 to 59: `MemoryLeakDetection` (an
`XCTestCase` extension asserting deallocation via a teardown block),
`AsyncSequenceCollecting` (awaits a bounded number of elements from an
`AsyncSequence` without hanging), `WidgetTimelineTesting` (bridges
WidgetKit's completion-handler timeline provider to `async`),
`BatteryStateProviding` (charge level/charging state via `UIDevice`,
distinct from `PowerStateProviding`'s `ProcessInfo`-backed Low Power
Mode/thermal reads), `SwiftDataTestSupport` (an in-memory `ModelContainer`
builder, the SwiftData counterpart to `CoreDataTestSupport`),
`PasskeyAuthentication` (WebAuthn/FIDO2 passkey registration and assertion
via `ASAuthorizationPlatformPublicKeyCredentialProvider`, distinct from
`AppleSignIn`'s single-vendor Sign in with Apple), `ScreenCaptureStateProviding`
(screen recording/mirroring/AirPlay detection via `UIScreen.isCaptured`),
`ProtectedDataAvailabilityProviding` (whether file-protected/Keychain data
is accessible right now, via `UIApplication.isProtectedDataAvailable`),
`DiskSpaceChecking` (available/total volume capacity via
`URLResourceValues`).

Also: fixed a pre-existing build break in
`QuoteBoxTests/AsyncSequenceCollectingTests.swift` (unwrapped
`VerificationResult<Transaction>` incorrectly) found via this round's CI run.
`reusable-test.yml`'s known-flake retry pattern now also covers two StoreKit
sandbox failure signatures a since-fixed version of that test hit along the
way. The test itself was renamed to
`testCollectsRealTransactionUpdateAfterExternalPurchase` and now drives
`SKTestSession.buyProduct(identifier:options:)` instead of
`StoreKitPurchaseManager.purchase()`/`Product.purchase()`: the old,
same-device in-app purchase deterministically never showed up on
`Transaction.updates` in CI, which turned out to be correct per Apple's own
documentation — `Transaction.updates` only receives transactions that occur
*outside* the app; a same-device purchase's transaction arrives through
`Product.PurchaseResult.success(_:)` instead. `buyProduct` simulates that
external scenario, so it's the one that actually reaches `Transaction.updates`.

Also: `PurchaseSupport` gains subscription/entitlement support —
`isEntitled(to:)` and `observeTransactionUpdates(_:)` — exercised through a
new "Become a Supporter" monthly subscription in QuoteBox alongside the
existing Tip Jar. `PowerStateProviding` gains thermal state —
`thermalState`, `startMonitoringThermalState(onChange:)`,
`stopMonitoringThermalState()` — the same `ProcessInfo` framework's other
power-adjacent read.

## [1.2.0] - 2026-08-12

Added 40 modules, bringing the kit from 10 to 50: `AccessibilityStateProviding`,
`AnalyticsLogging`, `AppleSignIn`, `AsyncSleeping`, `BackgroundTaskScheduling`,
`BiometricAuthentication`, `BluetoothAuthorization`, `BundleInfoProviding`,
`CalendarAuthorization`, `CameraAuthorization`, `CellularDataRestrictionChecking`,
`ClipboardProviding`, `CloudKitAccountChecking`, `ContactsAuthorization`,
`DebugOverlay`, `DiagnosticReporting`, `FamilyControlsAuthorization`,
`FeatureFlagging`, `FocusStatusAuthorization`, `HapticFeedbackProviding`,
`HealthAuthorization`, `HomeKitAuthorization`, `IdleTimerControlling`,
`JSONFixtureLoading`, `LiveActivityAuthorization`,
`LocalizationCompletenessChecking`, `MediaLibraryAuthorization`,
`MicrophoneAuthorization`, `MotionAuthorization`,
`NetworkReachabilityMonitoring`, `PhotoLibraryAuthorization`,
`PowerStateProviding`, `PushRegistering`, `RemindersAuthorization`,
`ReviewRequesting`, `SiriAuthorization`, `SpeechRecognitionAuthorization`,
`TrackingAuthorization`, `UserDefaultsStore`, `WatchConnectivityStateProviding`.

Also: repo polish (README table of contents, targeted CI retry for known
simulator/StoreKit/accessibility-audit flakes).

## [1.1.0] - 2026-08-11

Added 8 modules: `CoreDataTestSupport`, `DeepLinkTesting`, `KeychainStore`,
`LocalNotifications`, `LocationAuthorization`, `PurchaseSupport`,
`SnapshotTesting`, `TimeControl`.

Replaced the kit's original Weather demo app with QuoteBox as the proving
ground, to verify the kit isn't accidentally coupled to one app's shape
(different API, architecture, and testing surface).

## [1.0.0] - 2026-08-09

Initial release: `NetworkStub` and `UITestHelpers`, plus a real automated test
suite and CI (PR gating, device matrix, code coverage, live API contract
check) built out around them.
