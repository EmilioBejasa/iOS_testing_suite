# Changelog

All notable changes to this package are documented here. Versions correspond
to git tags; see the [README](README.md) for what each module does and how to
depend on it.

## [Unreleased]

Added 6 modules, bringing the kit from 50 to 56: `MemoryLeakDetection` (an
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
`AppleSignIn`'s single-vendor Sign in with Apple).

Also: fixed a pre-existing build break in
`QuoteBoxTests/AsyncSequenceCollectingTests.swift` (unwrapped
`VerificationResult<Transaction>` incorrectly) found via this round's CI run.
`reusable-test.yml`'s known-flake retry pattern now also covers
`testCollectsRealTransactionUpdateAfterPurchase`'s two observed StoreKit
sandbox failure modes (a `Transaction.updates` timeout, and a
`missingValue`/`advancedCommerceInfo` decode error), matched narrowly to
that one test so a real regression in `AsyncSequenceCollecting.collect()`
still fails fast. That retry confirmed the failure is deterministic (3/3
attempts, every device) rather than intermittent, so `ci.yml` now also
skips `testCollectsRealTransactionUpdateAfterPurchase` until someone with
Xcode/a Mac can diagnose why `Transaction.updates` isn't posting after a
real StoreKitTest sandbox purchase on the `macos-15` runner.

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
