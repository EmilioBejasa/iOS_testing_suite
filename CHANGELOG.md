# Changelog

All notable changes to this package are documented here. Versions correspond
to git tags; see the [README](README.md) for what each module does and how to
depend on it.

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
