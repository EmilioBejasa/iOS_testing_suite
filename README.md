# iOS Test Kit

[![iOS Build](https://github.com/EmilioBejasa/iOS_testing_suite/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/EmilioBejasa/iOS_testing_suite/actions/workflows/ci.yml)

A reusable iOS testing setup — a Swift package of test helpers, plus GitHub Actions
workflows any iOS repo can call by reference instead of copy-pasting CI config.

QuoteBox (`QuoteBox/`, `QuoteBoxTests/`, `QuoteBoxUITests/`) is the kit's proving
ground: a small demo app whose only job is to be a real, working consumer of every
module below, exercised through the same CI device matrix any app using this kit
would run. It replaced an earlier Weather demo app specifically to verify the kit
wasn't accidentally coupled to Weather's specifics — different API shape
(DummyJSON quotes, not Open-Meteo weather), different architecture (`@Observable` +
`TabView`, not `ObservableObject` MVVM + `NavigationStack`), different testing
surface (local persistence, not just network).

```sh
git clone https://github.com/EmilioBejasa/iOS_testing_suite
cd iOS_testing_suite
make setup   # or: ./Scripts/setup.sh — installs XcodeGen via Homebrew if missing
open QuoteBox.xcodeproj
```

## What's reusable

<details>
<summary><strong>Table of contents</strong> (59 modules, grouped by theme)</summary>

**Permissions & authorization**
[Location](#locationauthorization-swift-package-product) ·
[Photo Library](#photolibraryauthorization-swift-package-product) ·
[Contacts](#contactsauthorization-swift-package-product) ·
[Biometric](#biometricauthentication-swift-package-product) ·
[Camera](#cameraauthorization-swift-package-product) ·
[Microphone](#microphoneauthorization-swift-package-product) ·
[Speech Recognition](#speechrecognitionauthorization-swift-package-product) ·
[Calendar](#calendarauthorization-swift-package-product) ·
[Reminders](#remindersauthorization-swift-package-product) ·
[Tracking (ATT)](#trackingauthorization-swift-package-product) ·
[Health](#healthauthorization-swift-package-product) ·
[Motion](#motionauthorization-swift-package-product) ·
[Bluetooth](#bluetoothauthorization-swift-package-product) ·
[Siri](#siriauthorization-swift-package-product) ·
[Media Library](#medialibraryauthorization-swift-package-product) ·
[HomeKit](#homekitauthorization-swift-package-product) ·
[Focus Status](#focusstatusauthorization-swift-package-product) ·
[Family Controls](#familycontrolsauthorization-swift-package-product) ·
[Live Activity](#liveactivityauthorization-swift-package-product) ·
[Push Registering](#pushregistering-swift-package-product) ·
[Apple Sign In](#applesignin-swift-package-product) ·
[Passkey Authentication](#passkeyauthentication-swift-package-product) ·
[Background Task Scheduling](#backgroundtaskscheduling-swift-package-product) ·
[CloudKit Account Checking](#cloudkitaccountchecking-swift-package-product)

**Device & app state**
[Power State](#powerstateproviding-swift-package-product) ·
[Battery State](#batterystateproviding-swift-package-product) ·
[Screen Capture State](#screencapturestateproviding-swift-package-product) ·
[Protected Data Availability](#protecteddataavailabilityproviding-swift-package-product) ·
[Bundle Info](#bundleinfoproviding-swift-package-product) ·
[Cellular Data Restriction](#cellulardatarestrictionchecking-swift-package-product) ·
[Disk Space](#diskspacechecking-swift-package-product) ·
[Accessibility State](#accessibilitystateproviding-swift-package-product) ·
[Haptic Feedback](#hapticfeedbackproviding-swift-package-product) ·
[Idle Timer](#idletimercontrolling-swift-package-product) ·
[Clipboard](#clipboardproviding-swift-package-product) ·
[Watch Connectivity](#watchconnectivitystateproviding-swift-package-product) ·
[Network Reachability](#networkreachabilitymonitoring-swift-package-product)

**Persistence & networking**
[Network Stub](#networkstub-swift-package-product) ·
[Keychain Store](#keychainstore-swift-package-product) ·
[UserDefaults Store](#userdefaultsstore-swift-package-product) ·
[Core Data Test Support](#coredatatestsupport-swift-package-product) ·
[SwiftData Test Support](#swiftdatatestsupport-swift-package-product) ·
[Purchase Support](#purchasesupport-swift-package-product)

**Testing infrastructure & utilities**
[UI Test Helpers](#uitesthelpers-swift-package-product) ·
[Memory Leak Detection](#memoryleakdetection-swift-package-product) ·
[Async Sleeping](#asyncsleeping-swift-package-product) ·
[Async Sequence Collecting](#asyncsequencecollecting-swift-package-product) ·
[Time Control](#timecontrol-swift-package-product) ·
[Snapshot Testing](#snapshottesting-swift-package-product) ·
[Deep Link Testing](#deeplinktesting-swift-package-product) ·
[JSON Fixture Loading](#jsonfixtureloading-swift-package-product) ·
[Localization Completeness Checking](#localizationcompletenesschecking-swift-package-product) ·
[Widget Timeline Testing](#widgettimelinetesting-swift-package-product) ·
[Debug Overlay](#debugoverlay-swift-package-product)

**App behavior**
[Review Requesting](#reviewrequesting-swift-package-product) ·
[Local Notifications](#localnotifications-swift-package-product) ·
[Diagnostic Reporting](#diagnosticreporting-swift-package-product) ·
[Feature Flagging](#featureflagging-swift-package-product) ·
[Analytics Logging](#analyticslogging-swift-package-product)

**Also see:** [why CarPlay/MultipeerConnectivity/NFC aren't covered](#a-note-on-frameworks-this-kit-doesnt-cover) ·
[Reusable GitHub Actions workflows](#reusable-github-actions-workflows)

</details>

### `NetworkStub` (Swift Package product)

`URLProtocolStub` intercepts requests on a configured `URLSession` so any
`URLSession`-based network client can be tested against canned responses. The only
requirement on the app side is that the client accepts an injectable `URLSession`.

```swift
.package(url: "https://github.com/EmilioBejasa/iOS_testing_suite", from: "1.4.0")
// target dependency: .product(name: "NetworkStub", package: "iOS_testing_suite")
```

```swift
import NetworkStub

let configuration = URLSessionConfiguration.ephemeral
configuration.protocolClasses = [URLProtocolStub.self]
let session = URLSession(configuration: configuration)

URLProtocolStub.handler = { request in
    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    return (response, cannedJSON)
}
```

### `UITestHelpers` (Swift Package product)

An `XCUIApplication` extension for looking up elements by accessibility identifier
without guessing which `XCUIElementType` SwiftUI backed it with, plus a small
launch helper.

```swift
import UITestHelpers

let app = XCUIApplication().launched(withArguments: ["--mock-success"])
XCTAssertTrue(app.element("myList.list").waitForExistence(timeout: 5))
```

It also has `tab(_:)` — the same identifier-based `element(_:)` lookup can't find
tab bar buttons on every OS (iPadOS 18's floating tab bar backs items with a private
element type XCTest won't classify as `.tabBar`), so this searches by label across
every element type instead:

```swift
app.tab("Favorites").tap()
```

And `auditAccessibility()`, a thin wrapper around XCTest's built-in accessibility
audit (iOS 17+):

```swift
try app.auditAccessibility()
// or allow-list a specific known issue while still failing on anything else:
try app.auditAccessibility(allowing: { $0.auditType == .contrast && $0.element?.identifier == "known.lowContrastLogo" })
```

And `measureLaunch(withArguments:)`, an `XCTestCase` extension wrapping XCTest's
built-in `XCTApplicationLaunchMetric` around a fresh app launch:

```swift
func testAppLaunchPerformance() {
    measureLaunch(withArguments: ["--mock-success"])
}
```

Deliberately asserts no fixed pass/fail duration: `measure`'s baseline comparison
is tied to a specific device/Xcode version, which doesn't travel across a CI
matrix of ephemeral, variable-hardware runners — a hardcoded ceiling would flag
hardware noise, not real regressions. The numbers still land in the `.xcresult`
(already uploaded as a CI artifact by `reusable-test.yml`) for anyone tracking the
trend over time. `QuoteBoxUITests.testAppLaunchPerformance` exercises it.

`measureMemoryAndCPU(around:)` applies the same no-fixed-threshold reasoning to
`XCTMemoryMetric`/`XCTCPUMetric` instead of launch time. It takes a block
rather than launch arguments, unlike `measureLaunch` — what's worth profiling
here is a specific in-app interaction against an already-running app (scrolling
a list, switching tabs, repeating a fetch), not the launch itself:

```swift
func testScrollingPerformance() {
    let app = XCUIApplication().launched(withArguments: ["--mock-success"])
    measureMemoryAndCPU {
        app.element("myList.list").swipeUp()
    }
}
```

`QuoteBoxUITests.testFetchingNewQuotesRepeatedlyPerformance` exercises it,
repeatedly tapping "New Quote" to put `QuoteStore`'s fetch-and-replace cycle
(network stub round trip + view re-render) through enough iterations to be
worth profiling.

### `MemoryLeakDetection` (Swift Package product)

A third module shape, alongside `UITestHelpers`: an `XCTestCase` extension
usable only from a test target, not a protocol+`System`+`Mock` triad or a
pure-function utility — deallocation tracking has no real system framework
to wrap or fake, it's a property of ARC itself.

```swift
import MemoryLeakDetection

func testTipJarStoreDeallocatesAfterPurchasing() async {
    var store: TipJarStore? = TipJarStore(purchaseManager: MockPurchaseManager())
    trackForMemoryLeaks(store!)

    await store!.purchaseTip()

    store = nil
}
```

`trackForMemoryLeaks(_:file:line:)` registers a teardown block that asserts
the instance is `nil` by the end of the test via a `[weak instance]`
capture — call it right after constructing whatever you're tracking, and
hold no other strong reference to it for the rest of the test. A passing
assertion after teardown means nothing else (a delegate closure, an async
subscription, a parent-child retain cycle) is still keeping it alive.
Validated in `QuoteBoxTests/MemoryLeakDetectionTests.swift` against three of
QuoteBox's real reference-counted stores — `QuoteStore`, `TipJarStore`,
`CoreDataFavoritesStore` — each run through one real lifecycle action
(fetch, purchase, save) before being released.

### `AsyncSleeping` (Swift Package product)

The async counterpart to `TimeControl`'s `DateProviding` — that lets app code
ask "what time is it?" through an injectable dependency instead of calling
`Date()` directly; this lets app code ask "wait this long" through an
injectable dependency instead of calling `Task.sleep` directly. Matters for
any code that delays itself (retry backoff, debounce, polling loops) rather
than just reading the current time — a test driving that code through
`TimeControl` alone would still sit through the real wait.
`SystemSleeper` wraps `Task.sleep(for:)` (iOS 16+) directly — no bridging
needed, it's already the real `async throws` primitive every other module's
`System*` type is built on top of. `MockSleeper` records requested durations
and returns immediately instead of actually waiting.

```swift
import AsyncSleeping

let sleeper: AsyncSleeping = MockSleeper()
try await sleeper.sleep(for: .seconds(30)) // returns immediately in tests
```

Kit-level only — no code in `QuoteBox` currently self-delays (no retry
backoff, debounce, or polling loop), so there's nothing natural to wire it
into yet. `QuoteBoxTests/AsyncSleepingTests.swift` tests the mock fully, and
also exercises `SystemSleeper` for real with a short duration: unlike the
permission-gated modules above, there's no system prompt or crash risk here,
just an actual (brief) wait.

### `AsyncSequenceCollecting` (Swift Package product)

Not a protocol+real+fake module — there's nothing to fake, it's already a
pure, deterministic function, same "single-purpose utility" shape as
`JSONFixtureLoading`/`DeepLinkTesting`. Complements `AsyncSleeping`'s "inject
the wait" with "wait for the result": `AsyncSleeping` lets app code ask
"wait this long" through an injectable dependency, while this lets a *test*
await a bounded number of elements from a long-lived `AsyncSequence` without
hanging forever if fewer than expected ever arrive.

```swift
import AsyncSequenceCollecting

let transactions = try await AsyncSequenceCollecting.collect(
    Transaction.updates,
    count: 1,
    timeout: .seconds(5)
)
```

Deliberately covers `AsyncSequence`, not Combine: no `import Combine` exists
anywhere in this kit or in QuoteBox (`TipJarStore` is `@Observable`, not
`ObservableObject`), so bridging Combine publishers here would fake a
paradigm this kit's own consumer app never uses — the same "don't fake a
capability this kit doesn't have" reasoning behind excluding
CarPlay/MultipeerConnectivity/Core NFC below. `AsyncSequence` is different:
it's what Apple's own frameworks expose today, including `PurchaseSupport`'s
own `Transaction.updates` support (see `PurchaseSupport` below).

Not kit-level-only: `QuoteBoxTests/AsyncSequenceCollectingTests.swift`
simulates a purchase made *outside* the app via
`SKTestSession.buyProduct(identifier:options:)`, then calls
`collect(Transaction.updates, count: 1, timeout: .seconds(10))` and asserts
the collected transaction's `productID` — exactly the scenario this exists
for, since a bare `for try await` loop over `Transaction.updates` would
otherwise hang the test forever if the purchase somehow didn't post an
update. A second test drives an `AsyncStream` that never emits, to verify
`.timedOut` is thrown (reporting however many elements did arrive) rather
than silently returning a short array.

Deliberately doesn't purchase through `StoreKitPurchaseManager`/
`Product.purchase()` (a direct, same-device in-app purchase) the way an
earlier version of this test did: Apple's own documentation for
`Transaction.updates` says it receives transactions that occur *outside*
the app (Ask to Buy, offer codes, purchases from the App Store or another
device), and explicitly notes that a same-device in-app purchase's
transaction arrives through `Product.PurchaseResult.success(_:)` instead —
never through `Transaction.updates`. That earlier version timed out in CI
deterministically (0 collected, 3/3 retries, every device) even after
widening the timeout and adding a pre-purchase delay, which ruled out a
timing race — the actual problem was the documented contract, not timing.

### `FeatureFlagging` (Swift Package product)

The one module pair in this kit (with `AnalyticsLogging` below) that doesn't
wrap a single Apple framework — every other module here wraps a real system
API; this fills a very common real-world testing need instead: letting app
code ask "is this flag on?" through an injectable dependency so a test can
force either side of a flag-gated code path deterministically.
`SystemFeatureFlags` wraps raw `UserDefaults` directly rather than depending
on this kit's own `UserDefaultsStore` target — every module in this kit stays
independent (see `DebugOverlay`'s note on staying dependency-free below), so
this doesn't introduce the kit's first intra-module dependency. **Scope
note**, matching `SnapshotTesting`'s honesty pattern for what it doesn't
cover: this is a local override/QA-toggle mechanism (a bool read from
`"featureFlag.<name>"`), not a remote-config client — there's no single
vendor-neutral Apple framework for server-fetched flags the way there is for
every permission module above. `MockFeatureFlags` is a dictionary-backed
settable fake (`overrides: [String: Bool]`, unset flags default `false`) —
the actually valuable half for deterministic tests.

```swift
import FeatureFlagging

let flags: FeatureFlagging = MockFeatureFlags(overrides: ["newQuoteLayout": true])
if flags.isEnabled("newQuoteLayout") { /* ... */ }
```

Kit-level only — no code in `QuoteBox` is currently flag-gated. Both halves
are safe to test for real: `UserDefaults` reads/writes never prompt or crash,
so `QuoteBoxTests/FeatureFlaggingTests.swift` exercises `SystemFeatureFlags`
against a real (scratch, suite-scoped) `UserDefaults` instance, not just the
mock.

### `AnalyticsLogging` (Swift Package product)

Same scope as `FeatureFlagging`: lets app code report an analytics event
through an injectable dependency instead of calling a hardcoded analytics SDK
directly, so a test can assert on what was logged instead of needing a real
analytics backend. `SystemAnalyticsLogger` wraps `os.Logger` (`OSLog`, iOS
14+) as the closest first-party fit — there's no single Apple framework for
custom event analytics the way there is for, say, location or contacts, so
this isn't a stand-in for a specific vendor SDK. Only `SystemAnalyticsLogger`
itself needs `@available(iOS 14.0, *)`: unlike `BluetoothAuthorization`'s
`CBManagerAuthorization`, `Logger` never appears in `AnalyticsLogging`'s own
protocol signature, so the gate doesn't need to propagate there.
`MockAnalyticsLogger` records every logged call as a `[LoggedEvent]` (a small
`Equatable` struct, not a raw tuple, so tests can `XCTAssertEqual` cleanly) —
the valuable half for asserting "did my code log the right event."

```swift
import AnalyticsLogging

let logger: AnalyticsLogging = MockAnalyticsLogger()
logger.log(event: "quote_favorited", parameters: ["quoteID": "42"])
```

Kit-level only — no analytics events exist in `QuoteBox` yet. Both halves
safe to test for real: logging never prompts or crashes, so
`QuoteBoxTests/AnalyticsLoggingTests.swift` exercises `SystemAnalyticsLogger`
for real too, not just the mock.

### `TimeControl` (Swift Package product)

A `DateProviding` protocol so app code asks "what time is it?" through an
injectable dependency instead of calling `Date()` directly — the same
protocol+real+fake shape as a typical app-level `FavoritesStoring`-style
abstraction, just reusable across apps.

```swift
import TimeControl

let dateProvider = TestDateProvider(currentDate: Date(timeIntervalSince1970: 0))
let store = MyStore(dateProvider: dateProvider)
// ... exercise time-dependent logic ...
dateProvider.currentDate.addTimeInterval(60) // simulate a minute passing, no real sleep
```

### `NetworkReachabilityMonitoring` (Swift Package product)

Distinct from `NetworkStub` — that intercepts individual request/response pairs
on a `URLSession`; this reports the device's actual connectivity state.
`NetworkReachabilityMonitoring` keeps `NWPath.Status` directly
(`.satisfied`/`.unsatisfied`/`.requiresConnection`) rather than reinventing an
enum. `SystemNetworkReachabilityMonitor` wraps `NWPathMonitor`, running it on a
dedicated background queue (Apple's own requirement); `MockNetworkReachabilityMonitor`
is a settable fake with `simulateStatusChange(to:)` to drive updates manually.

```swift
import NetworkReachabilityMonitoring

let monitor: NetworkReachabilityMonitoring = MockNetworkReachabilityMonitor(currentStatus: .satisfied)
monitor.startMonitoring { status in print(status) }
```

`QuoteBox` wires this into `QuoteStore` (the same DI shape as its existing
`dateProvider`/`reminderScheduler` parameters) — real monitor in production,
`MockNetworkReachabilityMonitor(currentStatus: .satisfied)` under `--mock-*` for
determinism — and surfaces `networkStatus` as a new "Network" row in the Debug
tab's "Quote" section. Validated by
`QuoteBoxTests/NetworkReachabilityMonitoringTests.swift` (mock fully tested; the
real monitor is only constructed, never started — `NWPathMonitor.start(queue:)`
runs indefinitely with no synchronous "did it work" signal worth asserting on in
a unit test) and the extended `QuoteBoxUITests.testDebugTabShowsLaunchArgumentsAndAppState`.

### `KeychainStore` (Swift Package product)

A `KeychainStoring` protocol so app code isn't tied to `Security` framework calls
directly — same protocol+real+fake shape as `TimeControl`/`FavoritesStoring`.
`SystemKeychainStore` persists to the real Keychain (`kSecClassGenericPassword`,
scoped by a `service` string); `InMemoryKeychainStore` is a dictionary-backed fake
for fast, deterministic tests.

```swift
import KeychainStore

let store: KeychainStoring = SystemKeychainStore(service: "com.myapp.auth")
try store.save(tokenData, for: "authToken")
let token = try store.load(for: "authToken")
```

Validated directly against the Simulator's real Keychain in this repo's own tests
(`QuoteBoxTests/KeychainStoreTests.swift`) rather than through a QuoteBox feature —
a public quotes app has no natural secret to store, so there's no UI wiring here.
That real-Keychain test skips itself in this repo's own CI specifically, since
`reusable-test.yml` runs with `CODE_SIGNING_ALLOWED=NO` so any consumer can run CI
without a signing identity — but that also means the `keychain-access-groups`
entitlement Keychain access requires never gets embedded. It still runs and
validates real Keychain access normally on a signed build (a real device, or CI
with signing configured).

### `UserDefaultsStore` (Swift Package product)

A `UserDefaultsStoring` protocol, same protocol+real+fake shape as
`KeychainStore` — scoped to the two most common `UserDefaults` use cases
(counters, flags) rather than a generic `Codable` wrapper. `SystemUserDefaultsStore`
persists to real `UserDefaults` (optionally scoped to a `suiteName`);
`InMemoryUserDefaultsStore` is a dictionary-backed fake.

```swift
import UserDefaultsStore

let store: UserDefaultsStoring = SystemUserDefaultsStore()
store.setInteger(store.integer(for: "launchCount") + 1, for: "launchCount")
```

`QuoteBox` wires this into a real "Launch Count" feature: `QuoteBoxApp` increments
a counter on every `init()` — `SystemUserDefaultsStore` in production,
`InMemoryUserDefaultsStore` under `--mock-*` so the count is deterministically `1`
per launch instead of drifting with however many times the Simulator has actually
launched the app — and surfaces it in the `DebugOverlay` Debug tab's new "App"
section. Validated by `QuoteBoxTests/UserDefaultsStoreTests.swift` (round-trips
both implementations, mirroring `KeychainStoreTests.swift`'s pattern — no
entitlement/signing concern here, so no skip path is needed) and
`QuoteBoxUITests.testDebugTabShowsLaunchArgumentsAndAppState`.

### `ReviewRequesting` (Swift Package product)

Fire-and-forget by design, matching `AppStore.requestReview(in:)` itself: no
return value, and no way for any app — including the real one — to know whether
the system actually presented the prompt, since iOS rate-limits and decides that
on its own. `SystemReviewRequester` wraps `AppStore.requestReview(in:)`
(`StoreKit`, iOS 16+), finding the foreground-active `UIWindowScene`;
`MockReviewRequester` records `requestCount`, the only thing worth verifying
about a call this opaque even for the real implementation.

```swift
import ReviewRequesting

let requester: ReviewRequesting = MockReviewRequester()
requester.requestReview()
```

`QuoteBox` wires this into a real trigger by building on `UserDefaultsStore`'s
`launchCount`: `QuoteBoxApp.init()` calls `reviewRequester.requestReview()` when
`launchCount == 3` (`QuoteBoxApp.reviewRequestThreshold`), then passes a plain
`didRequestReviewThisLaunch: Bool` into `RootView` rather than a reference to the
requester itself — a real app can't introspect whether `AppStore.requestReview`
showed anything either, so the Debug tab's new "App" row honestly reflects only
"did our own trigger logic fire." Under `--mock-success`,
`InMemoryUserDefaultsStore` always makes `launchCount == 1`, so a new
`--launch-count <n>` launch argument (parsed the same way
`--mock-notifications-denied` already is) overrides `launchCount` directly to
`n` for that launch, letting `QuoteBoxUITests.testReviewRequestedAtLaunchCountThreshold`
force it to `3` deterministically.
`QuoteBoxTests/ReviewRequestingTests.swift` calls `SystemReviewRequester()` for
real — unlike `PushRegistering`/`AppleSignIn`'s prompting halves, this is
genuinely side-effect-safe, so there's nothing to avoid.

### `CoreDataTestSupport` (Swift Package product)

`InMemoryPersistentContainer.make(modelName:bundle:)` builds an `NSPersistentContainer`
backed by an in-memory store instead of on-disk SQLite, loaded synchronously — works
for any app's `.xcdatamodeld`, not just QuoteBox's.

```swift
import CoreDataTestSupport

let container = InMemoryPersistentContainer.make(modelName: "MyApp", bundle: Bundle(for: MyManagedObjectSubclass.self))
let store = MyCoreDataBackedStore(container: container)
// exercise store's save/load logic with no disk I/O and no state leaking between tests
```

`QuoteBox` uses this for real: `CoreDataFavoritesStore` is favorites' actual
production persistence (`QuoteBoxApp` builds a real on-disk container), and
`QuoteBoxTests/CoreDataFavoritesStoreTests.swift` proves it with the in-memory
container above — the same relationship `NetworkStub` has to the real `QuoteAPIClient`.

### `SwiftDataTestSupport` (Swift Package product)

`InMemoryModelContainer.make(for:)` builds a `ModelContainer` backed by an
in-memory store instead of SQLite on disk — the SwiftData counterpart to
`CoreDataTestSupport`'s `InMemoryPersistentContainer`, works for any app's
`@Model` types. Takes a plain `[any PersistentModel.Type]` array rather than
a variadic parameter: `ModelContainer`'s own initializer is itself variadic,
and Swift doesn't let one variadic parameter forward into another without
first collecting it into a `Schema`, so this builds the `Schema` (which does
take an array) explicitly rather than passing types straight through.
`@available(iOS 17.0, *)` since SwiftData itself is — newer than the
package's iOS 13 floor (`Package.swift`), same class of annotation
`BluetoothAuthorization` needed for `CBManagerAuthorization`.

```swift
import SwiftData
import SwiftDataTestSupport

let container = InMemoryModelContainer.make(for: [MyModel.self])
let context = ModelContext(container)
// exercise insert/fetch/save logic with no disk I/O and no state leaking between tests
```

**Scope note:** kit-level only, unlike `CoreDataTestSupport` — QuoteBox
already persists favorites through Core Data, and a second, parallel
SwiftData feature for the same data would be duplicative, not a natural
consumer. Exercised in `QuoteBoxTests/SwiftDataTestSupportTests.swift`
against a throwaway `@Model` type defined just for that test file instead,
the same "no natural QuoteBox need" treatment `KeychainStore`/
`LocationAuthorization` give their own kit-level-only modules.

### `LocalNotifications` (Swift Package product)

A `ReminderScheduling` protocol demonstrating the pattern for testing any
permission-gated system service: request authorization and act through an
injectable dependency, so a UI test can swap in a fake and never trigger the real
system permission dialog (which XCTest can't dismiss headlessly — it would hang
CI). `SystemReminderScheduler` wraps `UNUserNotificationCenter`;
`MockReminderScheduler` is a settable fake that records what it was asked to do.
The same shape generalizes to other system permissions (location, camera, photos)
even though only notifications ships concretely here.

```swift
import LocalNotifications

let scheduler: ReminderScheduling = MockReminderScheduler(authorizationResult: .authorized)
let status = await scheduler.requestAuthorization()
if status == .authorized {
    try await scheduler.scheduleDailyReminder(hour: 9, minute: 0)
}
```

`QuoteBox` wires this in exactly like `QuoteAPIClientProtocol`: real
`SystemReminderScheduler` in production, `MockReminderScheduler` under
`--mock-success`/`--mock-error`, with a `--mock-notifications-denied` launch
argument (mirroring `--mock-error`) to exercise the denied-permission UI path
deterministically.

### `SnapshotTesting` (Swift Package product)

`assertSnapshot(of:size:named:)` renders a SwiftUI view via `ImageRenderer` (iOS
16+) and compares it against a reference PNG checked into the repo next to the
calling test file, under `__Snapshots__/<TestFileName>/`. Rendered at a fixed size
and scale rather than the device's actual screen dimensions, so one reference
image stays valid across an entire CI device matrix instead of needing a baseline
per simulator — and since it reads/writes the PNG by file path (not as an app
bundle resource), no Xcode resource wiring is needed either.

```swift
import SnapshotTesting

assertSnapshot(of: MyView(), size: CGSize(width: 320, height: 500), named: "loaded")
```

Set `SNAPSHOT_RECORD=1` to write a new reference image instead of comparing — the
test still fails when recording, so it can't be left on by accident. Runs as a
plain unit test (no simulator UI interaction, no XCUITest involved). Pass it as
a bare `xcodebuild` build-setting override —
`xcodebuild test ... SNAPSHOT_RECORD=1`, the same style as
`CODE_SIGNING_ALLOWED=NO` — rather than a shell `export`: a Simulator-hosted
test process only sees environment variables the scheme explicitly maps in
(`project.yml`'s `test` scheme sets `SNAPSHOT_RECORD: $(SNAPSHOT_RECORD)`), not
the invoking shell's environment. `.github/workflows/record-snapshots.yml`
does this for you if you don't have a local Mac.

`assertSnapshot` also takes optional `locale:`/`dynamicTypeSize:` parameters,
defaulting to `nil` so every existing call site (QuoteBox's included) renders
exactly as before:

```swift
assertSnapshot(of: MyView(), dynamicTypeSize: .accessibility3, named: "loaded-accessibility3")
```

This replaces relying on an accessibility audit's allow-listed exception with
actually rendering and comparing the larger size — no automatic filename
suffixing, the caller names each variant explicitly via `named:`, same as today.
`QuoteBoxTests/QuoteViewSnapshotTests.swift`'s
`testQuoteContentViewLoadedAccessibility3` exercises this against
`QuoteContentView` — a taller frame than the default-size snapshot
(`CGSize(width: 300, height: 400)` vs. 150), since `.accessibility3` text
needs materially more vertical room to lay out without clipping. Recorded via
`.github/workflows/record-snapshots.yml` rather than a local Mac (see that
workflow's own history: the first attempt surfaced a real bug — a shell-level
`SNAPSHOT_RECORD=1` never reached the Simulator-hosted test process until
`project.yml`'s `test` scheme gained an explicit `SNAPSHOT_RECORD:
$(SNAPSHOT_RECORD)` environment-variable mapping).

### `DeepLinkTesting` (Swift Package product)

`DeepLinkSource.url(from:)` looks for `--deep-link <url>` in launch arguments.
`XCUIDevice.shared.system.open(url:)` — the obvious way to test deep links — opens
a real system "Open in 'MyApp'" confirmation dialog that a synchronous UI-test
call can't dismiss, which would hang CI. This sidesteps that entirely: a UI test
passes the URL as a launch argument, and the app reads it at startup exactly like
it already does for `--mock-success`/`--mock-error`, testing the app's own
URL-to-route parsing and resulting UI state without touching the real OS-level
open dialog.

```swift
import DeepLinkTesting

// in the app, alongside existing launch-argument handling:
let route = DeepLinkSource.url(from: ProcessInfo.processInfo.arguments).flatMap(MyRoute.init(url:))
```

```swift
// in a UI test:
let app = XCUIApplication().launched(withArguments: ["--deep-link", "myapp://favorites"])
```

`QuoteBox` wires this in via `QuoteBoxRoute` (`quotebox://favorites` opens the
Favorites tab) — plain Swift, no kit dependency needed for the URL-parsing part.
The real `.onOpenURL` production path and the test launch-argument path both flow
through the same `QuoteBoxRoute?` binding, so either one can drive navigation.

`UniversalLinkSource.url(from:)` applies the identical technique to a second
real-world trigger: Universal Links arrive via `NSUserActivity`/
`.onContinueUserActivity(NSUserActivityTypeBrowsingWeb)`, not `.onOpenURL`, so
they need their own launch argument (`--universal-link <url>`) rather than
reusing `--deep-link`. This deliberately stayed a second file in this same
module rather than a new package — the reusable part is the *technique*
(launch-argument URL instead of a real, headless-undismissable system dialog),
which isn't specific to custom URL schemes, not a distinct system framework the
way every other module here wraps one.

```swift
// in a UI test:
let app = XCUIApplication().launched(withArguments: ["--universal-link", "https://myapp.com/favorites"])
```

`QuoteBox`'s `QuoteBoxRoute.init?(url:)` matches both shapes
(`quotebox://favorites` and `https://quotebox.qa/favorites`, a placeholder
domain — no real Associated Domains entitlement was added, same reasoning
`DeepLinkTesting` already gives for never touching the real open dialog), and
`QuoteBoxApp` drives the same `route` binding from `.onContinueUserActivity`
alongside `.onOpenURL`.

### `LocationAuthorization` (Swift Package product)

A second permission-gated system service, following `LocalNotifications`'s
protocol+real+fake shape. Uses `CLAuthorizationStatus` directly (CoreLocation's
own richer type — `notDetermined`/`restricted`/`denied`/`authorizedWhenInUse`/`authorizedAlways`)
rather than reinventing a simplified enum that would lose that distinction.
`SystemLocationAuthorizer` bridges `CLLocationManager`'s delegate-based
authorization callback to `async`; `MockLocationAuthorizer` is a settable fake.

```swift
import LocationAuthorization

let authorizer: LocationAuthorizing = MockLocationAuthorizer(status: .authorizedWhenInUse)
let status = await authorizer.requestWhenInUseAuthorization()
```

Validated directly in this repo's tests rather than through a QuoteBox feature —
same reasoning as `KeychainStore`: a public quotes app has no natural need for
location. There's a second reason here too: automated tests never call
`requestWhenInUseAuthorization()` against the real authorizer. When status is
`.notDetermined`, that triggers an actual system permission alert XCTest can't
dismiss headlessly — unlike `LocalNotifications`, where `--mock-*` launch
arguments keep the real permission API out of UI tests entirely, testing that
same interactive path here would risk hanging the run, not just failing it.

### `PhotoLibraryAuthorization` (Swift Package product)

A third permission-gated system service, following the same protocol+real+fake
shape. Uses `PHAuthorizationStatus` directly (Photos' own richer type —
`notDetermined`/`restricted`/`denied`/`authorized`/`limited`) rather than
reinventing a simplified enum that would lose the `.limited` (partial photo
access) case. `SystemPhotoLibraryAuthorizer` wraps `PHPhotoLibrary` — unlike
`CLLocationManager`, Photos already exposes a native `async` authorization API
(iOS 14+), so no delegate/continuation bridging is needed here the way
`LocationAuthorization` requires. `MockPhotoLibraryAuthorizer` is a settable fake.

```swift
import PhotoLibraryAuthorization

let authorizer: PhotoLibraryAuthorizing = MockPhotoLibraryAuthorizer(status: .authorized)
let status = await authorizer.requestAuthorization()
```

Same "kit-level only" treatment as `LocationAuthorization`, for the same two
reasons: a quotes app has no natural need for photo access, and automated tests
never call `requestAuthorization()` against the real authorizer — only the safe,
non-prompting `currentAuthorizationStatus()` read
(`QuoteBoxTests/PhotoLibraryAuthorizationTests.swift`).

### `ContactsAuthorization` (Swift Package product)

A fourth permission-gated system service, same protocol+real+fake shape again.
Uses `CNAuthorizationStatus` directly, same reasoning as the others for keeping
a framework's own status type. `SystemContactsAuthorizer` wraps `CNContactStore`:
`requestAccess(for:completionHandler:)` is already a plain completion handler
(not a delegate), so it bridges to `async` directly via `CheckedContinuation` —
no `NSObject`/delegate subclass needed, simpler than `LocationAuthorization`'s
bridge. `MockContactsAuthorizer` is a settable fake.

```swift
import ContactsAuthorization

let authorizer: ContactsAuthorizing = MockContactsAuthorizer(status: .authorized)
let granted = await authorizer.requestAccess()
```

Same "kit-level only" treatment again: a quotes app has no natural need for
contacts, and automated tests never call `requestAccess()` against the real
authorizer — only the safe, non-prompting, static
`CNContactStore.authorizationStatus(for:)` read
(`QuoteBoxTests/ContactsAuthorizationTests.swift`).

### `BiometricAuthentication` (Swift Package product)

Face ID/Touch ID doesn't fit the permission-status shape the way Location/Photos
do: `LAContext` has no persisted "authorization status" to read back later, only
a synchronous capability check (`canEvaluate()`, is biometric auth configured on
this device right now — never prompts) and an evaluation that always prompts
(`evaluate(reason:)`). `SystemBiometricAuthenticator` bridges `LAContext`'s
completion-handler-based `evaluatePolicy` to `async` via `CheckedContinuation` —
simpler than `LocationAuthorization`'s bridge, since there's a completion closure
to resume from directly rather than a delegate callback.
`MockBiometricAuthenticator` has independently settable `canEvaluateResult`/
`evaluateResult`.

```swift
import BiometricAuthentication

let authenticator: BiometricAuthenticating = MockBiometricAuthenticator()
guard authenticator.canEvaluate() else { return }
let unlocked = await authenticator.evaluate(reason: "Unlock QuoteBox")
```

Same "kit-level only" treatment again: `QuoteBoxTests/BiometricAuthenticationTests.swift`
tests the mock fully, and the real authenticator is only exercised via
`canEvaluate()` — never `evaluate()`, which would trigger the real,
headless-undismissable Face ID/Touch ID system prompt.

### `CameraAuthorization` (Swift Package product)

A fifth permission-gated system service, same protocol+real+fake shape as
`LocationAuthorization`/`PhotoLibraryAuthorization`/`ContactsAuthorization`.
Uses `AVAuthorizationStatus` directly, same reasoning every other module here
gives for keeping a framework's own status type. `SystemCameraAuthorizer`
wraps `AVCaptureDevice`: `requestAccess(for:completionHandler:)` is already a
plain completion handler (not a delegate), so it bridges to `async` directly
via `CheckedContinuation` — no delegate subclass needed, the same shape as
`SystemContactsAuthorizer`. `MockCameraAuthorizer` is a settable fake.

```swift
import CameraAuthorization

let authorizer: CameraAuthorizing = MockCameraAuthorizer(status: .authorized)
let granted = await authorizer.requestAccess()
```

Same "kit-level only" treatment as `LocationAuthorization`/`ContactsAuthorization`:
a quotes app has no natural need for the camera, and automated tests never call
`requestAccess()` against the real authorizer — only the safe, non-prompting
`AVCaptureDevice.authorizationStatus(for:)` read
(`QuoteBoxTests/CameraAuthorizationTests.swift`). Calling the real
`requestAccess()` here would be worse than just prompting: QuoteBox's
`Info.plist` has no `NSCameraUsageDescription` key, so it would crash the test
host outright rather than show a dialog XCTest merely can't dismiss.

### `MicrophoneAuthorization` (Swift Package product)

A sixth permission-gated system service, same shape as `CameraAuthorization`.
Deliberately checks the `.audio` media type through `AVCaptureDevice` rather
than `AVAudioApplication`'s `recordPermission` (the other native option, iOS
17+) — that would raise this module's floor above the package's iOS 13
minimum for a distinction (audio-session recording vs. capture-device audio)
no app in this kit needs, and it would give `CameraAuthorization`/
`MicrophoneAuthorization` two different status enum families instead of
sharing `AVAuthorizationStatus`. `SystemMicrophoneAuthorizer` bridges the same
way `SystemCameraAuthorizer` does; `MockMicrophoneAuthorizer` is a settable
fake.

```swift
import MicrophoneAuthorization

let authorizer: MicrophoneAuthorizing = MockMicrophoneAuthorizer(status: .authorized)
let granted = await authorizer.requestAccess()
```

Same "kit-level only" treatment again, for the same two reasons
`CameraAuthorization` gives: no natural QuoteBox need, and no
`NSMicrophoneUsageDescription` key in `Info.plist` to safely request against
the real authorizer (`QuoteBoxTests/MicrophoneAuthorizationTests.swift` reads
status only).

### `SpeechRecognitionAuthorization` (Swift Package product)

A seventh permission-gated system service, same protocol+real+fake shape
again. Uses `SFSpeechRecognizerAuthorizationStatus` directly — it has no
`.limited`/`.restricted`-style nuance the others carry, but reinventing an
enum here would make this module the odd one out. `SystemSpeechRecognitionAuthorizer`
wraps `SFSpeechRecognizer`: `requestAuthorization(_:)` is already a plain
completion handler, bridged to `async` via `CheckedContinuation` the same way
`SystemContactsAuthorizer` is. `MockSpeechRecognitionAuthorizer` is a settable
fake.

```swift
import SpeechRecognitionAuthorization

let authorizer: SpeechRecognitionAuthorizing = MockSpeechRecognitionAuthorizer(status: .authorized)
let result = await authorizer.requestAuthorization()
```

Same "kit-level only" treatment again: no natural QuoteBox need, and no
`NSSpeechRecognitionUsageDescription` key in `Info.plist` to safely request
against the real recognizer
(`QuoteBoxTests/SpeechRecognitionAuthorizationTests.swift` reads status only).

### `CalendarAuthorization` (Swift Package product)

An eighth permission-gated system service, same protocol+real+fake shape as
`ContactsAuthorization`/`CameraAuthorization`. Uses `EKAuthorizationStatus`
directly — iOS 17 added `.fullAccess`/`.writeOnly` cases this module would
lose by reinventing a simplified enum. `SystemCalendarAuthorizer` wraps
`EKEventStore`: unlike `SystemContactsAuthorizer`, no completion-handler
bridging is needed — `requestFullAccessToEvents()` (iOS 17+) is already a
native `async throws` API, the same "already async" story
`SystemPhotoLibraryAuthorizer` gives for `PHPhotoLibrary`. Deliberately
targets that iOS 17 API rather than the older, deprecated
`requestAccess(to:completion:)`: QuoteBox's own deployment target is already
17.0 (`project.yml`'s `IPHONEOS_DEPLOYMENT_TARGET`), so there's no floor this
module needs to stay under the way `MicrophoneAuthorization` does for
`AVAudioApplication`. `MockCalendarAuthorizer` is a settable fake.

```swift
import CalendarAuthorization

let authorizer: CalendarAuthorizing = MockCalendarAuthorizer(status: .fullAccess)
let granted = await authorizer.requestAccess()
```

Same "kit-level only" treatment as `ContactsAuthorization`: a quotes app has
no natural need for calendar access, and automated tests never call
`requestAccess()` against the real authorizer — only the safe, non-prompting
`EKEventStore.authorizationStatus(for:)` read
(`QuoteBoxTests/CalendarAuthorizationTests.swift`). QuoteBox's `Info.plist`
has no `NSCalendarsFullAccessUsageDescription` key, so calling the real
`requestAccess()` here would crash the test host outright rather than just
show a dialog XCTest can't dismiss.

### `TrackingAuthorization` (Swift Package product)

A ninth permission-gated system service, same shape as the others. Uses
`ATTrackingManager.AuthorizationStatus` directly, same reasoning every other
module here gives for keeping a framework's own status type.
`SystemTrackingAuthorizer` wraps `ATTrackingManager`:
`requestTrackingAuthorization(completionHandler:)` is a plain completion
handler, bridged to `async` via `CheckedContinuation` the same way
`SystemContactsAuthorizer` is. `MockTrackingAuthorizer` is a settable fake.

```swift
import TrackingAuthorization

let authorizer: TrackingAuthorizing = MockTrackingAuthorizer(status: .authorized)
let result = await authorizer.requestAuthorization()
```

Distinct from every other permission in this kit in *why* it matters: it's
the one gate here tied directly to App Store review requirements (Apple
rejects apps that track across other companies' apps/websites without first
showing this prompt), not just a nice-to-have capability check. Still
kit-level only, for the same structural reasons as the rest: no natural
QuoteBox need (it doesn't track anything), and no
`NSUserTrackingUsageDescription` key in `Info.plist` to safely request
against the real manager
(`QuoteBoxTests/TrackingAuthorizationTests.swift` reads status only).

### `HealthAuthorization` (Swift Package product)

A tenth permission-gated system service, same protocol+real+fake shape as
`ContactsAuthorization`. Uses `HKAuthorizationStatus` directly, same reasoning
every other module here gives for keeping a framework's own status type.
Parameterized by `HKObjectType` rather than a single fixed data type, since
HealthKit authorization is always scoped per data type - there's no single
"is HealthKit authorized" status the way Contacts or Photos have.
`SystemHealthAuthorizer` wraps `HKHealthStore`, deliberately bridging the
older completion-handler `requestAuthorization(toShare:read:completion:)`
(available since iOS 8) via `CheckedContinuation` rather than adopting the
iOS 15+ native `async throws` overload - keeps this module at the package's
iOS 13 floor with no extra `@available` annotations needed anywhere, same
reasoning `MicrophoneAuthorization` gives for avoiding `AVAudioApplication`.
`MockHealthAuthorizer` is a settable fake whose `currentAuthorizationStatus(for:)`
ignores its `type` parameter and returns the one stored status - a per-type
dictionary would be premature abstraction nothing here needs.

```swift
import HealthAuthorization

let authorizer: HealthAuthorizing = MockHealthAuthorizer(status: .sharingAuthorized)
let granted = await authorizer.requestAuthorization(toShare: [], read: [stepCountType])
```

Treated with `CloudKitAccountChecking`'s most conservative caution, not
Contacts/Location's: HealthKit needs the `com.apple.developer.healthkit`
entitlement QuoteBox doesn't have, and HealthKit is unavailable on iPad
entirely (`HKHealthStore.isHealthDataAvailable()` is always `false` there) -
this repo's own CI device matrix includes an iPad. So
`QuoteBoxTests/HealthAuthorizationTests.swift` doesn't even call the
normally-safe status read against the real authorizer - it only constructs
`SystemHealthAuthorizer()`, the same "documented risk, untested real path"
treatment `CloudKitAccountCheckingTests` gives `CKContainer.accountStatus()`.

### `MotionAuthorization` (Swift Package product)

An eleventh permission-gated system service - but unlike every other
authorization module in this kit, there's no explicit "request authorization"
API: Core Motion prompts implicitly the first time the app starts using the
service (`CMMotionActivityManager.startActivityUpdates`), not via a separate
async call. So `MotionAuthorizing` only has a status read, no
`requestAuthorization()`. Uses `CMAuthorizationStatus` directly.
`SystemMotionAuthorizer` wraps `CMMotionActivityManager.authorizationStatus()`
- a static, synchronous, non-prompting read, so no bridging is needed.
`MockMotionAuthorizer` is a settable fake.

```swift
import MotionAuthorization

let authorizer: MotionAuthorizing = MockMotionAuthorizer(status: .authorized)
let status = authorizer.currentAuthorizationStatus()
```

Kit-level only - no natural QuoteBox need - but the real authorizer's status
read is safe to exercise for real (`QuoteBoxTests/MotionAuthorizationTests.swift`
does), same as most other modules' status-only-safe pattern.

### `BluetoothAuthorization` (Swift Package product)

A twelfth permission-gated system service, same structural outlier as
`MotionAuthorization`: Bluetooth authorization is requested implicitly when a
`CBCentralManager` is instantiated and used, not via a separate explicit
request call, so this protocol only has a status read too.

`CBManagerAuthorization`/`CBManager.authorization` is `@available(iOS 13.1, *)`
in Apple's headers - newer than the package's iOS 13 floor - so merely naming
the type requires this annotation on the protocol, `SystemBluetoothAuthorizer`,
*and* `MockBluetoothAuthorizer` alike, the same class of fix
`TrackingAuthorizing` needed for `ATTrackingManager` and `AsyncSleeping`
needed for `Duration`. Applied here from the start rather than discovered via
a failed CI run. `SystemBluetoothAuthorizer` reads `CBManager.authorization`
(static, non-prompting - reading it doesn't trigger the prompt, only
actually starting/using a `CBCentralManager` does). `MockBluetoothAuthorizer`
is a settable fake.

```swift
import BluetoothAuthorization

let authorizer: BluetoothAuthorizing = MockBluetoothAuthorizer(status: .allowedAlways)
let status = authorizer.currentAuthorizationStatus()
```

Kit-level only; the real status read is safe to exercise for real
(`QuoteBoxTests/BluetoothAuthorizationTests.swift` does).

### `SiriAuthorization` (Swift Package product)

A thirteenth permission-gated system service, same protocol+real+fake shape
as `SpeechRecognitionAuthorization`. Uses `INSiriAuthorizationStatus`
directly. `SystemSiriAuthorizer` wraps `INPreferences`:
`requestSiriAuthorization(_:)` is a plain completion handler, bridged to
`async` via `CheckedContinuation`. `MockSiriAuthorizer` is a settable fake.

```swift
import SiriAuthorization

let authorizer: SiriAuthorizing = MockSiriAuthorizer(status: .authorized)
let result = await authorizer.requestAuthorization()
```

Kit-level only, and stricter than every other permission module in this kit:
`INPreferences` requires the `com.apple.developer.siri` entitlement QuoteBox
doesn't have just to *use the class at all* - even the normally-safe status
read crashes without it (`NSInternalInconsistencyException`, found via a
failed CI run, not assumed in advance). So
`QuoteBoxTests/SiriAuthorizationTests.swift` doesn't call any method on the
real authorizer, only constructs it - the same "documented risk, untested
real path" treatment `HealthAuthorizationTests`/`CloudKitAccountCheckingTests`
give their real authorizers.

### `MediaLibraryAuthorization` (Swift Package product)

A fourteenth permission-gated system service, same shape again. Uses
`MPMediaLibraryAuthorizationStatus` directly. `SystemMediaLibraryAuthorizer`
wraps `MPMediaLibrary`: `requestAuthorization(_:)` is a plain completion
handler, bridged to `async` via `CheckedContinuation`.
`MockMediaLibraryAuthorizer` is a settable fake.

```swift
import MediaLibraryAuthorization

let authorizer: MediaLibraryAuthorizing = MockMediaLibraryAuthorizer(status: .authorized)
let result = await authorizer.requestAuthorization()
```

Kit-level only, no `NSAppleMusicUsageDescription` key in `Info.plist` -
`QuoteBoxTests/MediaLibraryAuthorizationTests.swift` reads status only.

### `DiagnosticReporting` (Swift Package product)

Wraps `MetricKit`, a system framework with a completely different shape from
every authorization module above: there's no permission prompt and no status
enum at all - `MXMetricManager.shared.add(subscriber:)`/`.remove(subscriber:)`
is pure opt-in subscription, so this protocol just exposes start/stop rather
than a status read. `SystemDiagnosticReporter` is an `NSObject` subclass
(`MXMetricManagerSubscriber` requires `NSObjectProtocol` conformance, unlike
most other `System*` types in this kit) with no-op `didReceive` handlers -
`MXMetricPayload`/`MXDiagnosticPayload` have no public initializer, the same
"can't fabricate Apple's own type" story `BackgroundTaskScheduling`/
`PurchaseSupport`/`AppleSignIn` already give. `MockDiagnosticReporter` records
whether reporting was started rather than faking real payloads, the same
"records what a call site asked for" shape `MockBackgroundTaskScheduler` uses.

```swift
import DiagnosticReporting

let reporter: DiagnosticReporting = MockDiagnosticReporter()
reporter.startReporting()
```

Kit-level only - no natural QuoteBox feature - but unlike every other
kit-level-only module, MetricKit has no prompt and no crash risk from a
missing entitlement, so `QuoteBoxTests/DiagnosticReportingTests.swift`
exercises the real reporter's start/stop fully, the same "safe to call for
real" category `ReviewRequesting` is in.

### `PushRegistering` (Swift Package product)

Distinct from `LocalNotifications`'s `ReminderScheduling`, which covers the
alert/badge/sound *authorization* prompt shared by local and remote
notifications. This covers the separate second step: registering the device
with APNs. Unlike a permission request, `registerForRemoteNotifications()`
never shows a system dialog — the Simulator hands back a synthetic token
instantly. `SystemPushRegistrar` bridges it to `async` via
`CheckedContinuation`, but the result only arrives through
`UIApplicationDelegate` callbacks (`didRegister(deviceToken:)`/
`didFailToRegister(error:)`), not a completion handler, so a host app has to
forward those two methods into it itself. `MockPushRegistrar` is a settable
fake.

```swift
import PushRegistering

let registrar: PushRegistering = MockPushRegistrar(outcome: .token(deviceTokenData))
let outcome = await registrar.registerForRemoteNotifications()
```

Kit-level only — `QuoteBox` has no server that ever sends it a push, so it
doesn't add the `UIApplicationDelegate` forwarding `SystemPushRegistrar` needs.
That's *why* `QuoteBoxTests/PushRegisteringTests.swift` only constructs the real
registrar rather than awaiting it: nothing routes the OS callback into it, so
awaiting would hang forever waiting on a continuation nothing resumes — a
structural reason, distinct from `LocationAuthorization`'s "would show a real
dialog."

### `AppleSignIn` (Swift Package product)

`AppleSignInProviding` wraps `ASAuthorizationAppleIDProvider`/
`ASAuthorizationController`. `credentialState(for:)` wraps a plain completion
handler directly as `async` — no delegate, and it never prompts.
`requestSignIn()` bridges `ASAuthorizationControllerDelegate`'s callbacks the
same way `SystemLocationAuthorizer` bridges `CLLocationManagerDelegate`, and
always shows the real system sign-in sheet. Returns a plain `AppleIDCredential`
struct rather than Apple's own `ASAuthorizationAppleIDCredential` — that type has
no public initializer (the same constraint `PurchaseSupport` documents for
StoreKit's `Product`), so `MockAppleSignInProvider` couldn't construct one to
return. `ASAuthorizationAppleIDProvider.CredentialState` doesn't have that
problem (a plain enum), so it's kept as Apple's own type, same reasoning
`LocationAuthorization` gives for keeping `CLAuthorizationStatus` as-is.

```swift
import AppleSignIn

let provider: AppleSignInProviding = MockAppleSignInProvider()
let credential = try await provider.requestSignIn()
```

Kit-level only, same reasoning as `LocationAuthorization`/`KeychainStore` — a
quotes app has no natural need for user accounts. `credentialState(for:)` is
safe to exercise for real (resolves quickly with `.notFound` for an unused ID,
never prompts) and is tested against the real provider in
`QuoteBoxTests/AppleSignInTests.swift`; `requestSignIn()` is never called
against the real provider, since it always shows the actual system sheet.

### `PasskeyAuthentication` (Swift Package product)

Distinct from `AppleSignIn`: that wraps Sign in with Apple
(`ASAuthorizationAppleIDProvider`), a single-vendor identity; this wraps
passkeys (`ASAuthorizationPlatformPublicKeyCredentialProvider`), the
standards-based WebAuthn/FIDO2 credential every platform is converging on as
a passwordless replacement for passwords. Scoped to registration (creating a
new passkey) and assertion (signing in with an existing one) — the two
operations a relying-party server actually needs, not a full WebAuthn
client. `SystemPasskeyAuthenticator` bridges
`ASAuthorizationControllerDelegate`'s callbacks the same way
`SystemAppleSignInProvider` does. Returns plain `PasskeyRegistration`/
`PasskeyAssertion` structs rather than Apple's own
`ASAuthorizationPlatformPublicKeyCredentialRegistration`/`...Assertion` —
those are classes with no public initializer (the same constraint
`AppleSignIn` already documents for `ASAuthorizationAppleIDCredential`), so
`MockPasskeyAuthenticator` couldn't construct one to return.

```swift
import PasskeyAuthentication

let authenticator: PasskeyAuthenticating = MockPasskeyAuthenticator()
let registration = try await authenticator.requestRegistration(challenge: challenge, userName: "user@example.com", userID: userID)
```

Neither `PasskeyAuthenticating` nor `MockPasskeyAuthenticator` names an
`AuthenticationServices` passkey type directly, so unlike
`BluetoothAuthorization`/`CalendarAuthorization` neither needs an
`@available` annotation — only `SystemPasskeyAuthenticator`, which
constructs `ASAuthorizationPlatformPublicKeyCredentialProvider` directly,
needs `@available(iOS 15.0, *)`.

Kit-level only, same reasoning as `AppleSignIn` — a quotes app has no
natural need for user accounts. Unlike `AppleSignIn`, there's no
non-prompting half here at all: both `requestRegistration`/
`requestAssertion` always show the real system passkey sheet, so
`QuoteBoxTests/PasskeyAuthenticationTests.swift` only constructs
`SystemPasskeyAuthenticator` for real (safe — `relyingPartyIdentifier` is
just stored, no `AuthenticationServices` call happens until a request is
made) and tests the mock fully.

### `BackgroundTaskScheduling` (Swift Package product)

Wraps `BGTaskScheduler.shared` directly — `SystemBackgroundTaskScheduler` needs
no bridging, but also no safety net. `MockBackgroundTaskScheduler` records what
a call site asked the scheduler to do (registered identifiers, submitted/
cancelled requests) rather than faking real scheduling behavior: it can't invoke
a registered launch handler with a working fake `BGTask`, since — like
StoreKit's `Product` and `ASAuthorizationAppleIDCredential` above — `BGTask` has
no public initializer.

```swift
import BackgroundTaskScheduling

let scheduler: BackgroundTaskScheduling = MockBackgroundTaskScheduler()
scheduler.register(forTaskWithIdentifier: "com.myapp.refresh") { task in /* ... */ }
try scheduler.submit(BGAppRefreshTaskRequest(identifier: "com.myapp.refresh"))
```

Kit-level only, and — a third, distinct reason from `PushRegistering` and
`AppleSignIn` above — the real implementation isn't exercised *at all* here, not
even a safe subset. `BGTaskScheduler.register()`/`.submit()` have real,
version-spanning crash reports tied to registration timing (must happen before
the app finishes launching) and to identifiers missing from `Info.plist`'s
`BGTaskSchedulerPermittedIdentifiers`. A plain `XCTest` run is exactly that kind
of non-standard invocation context, so unlike a system dialog (avoidable) or an
unresolved continuation (harmless if never awaited), there's credible risk the
real scheduler crashes the test host outright.
`QuoteBoxTests/BackgroundTaskSchedulingTests.swift` tests only the mock.

### `CloudKitAccountChecking` (Swift Package product)

`CloudKitAccountChecking` keeps `CKAccountStatus` directly, same reasoning as
every other status-checking module for keeping a framework's own type.
`SystemCloudKitAccountChecker` wraps `CKContainer.default().accountStatus()`
(native async throwing API, iOS 15+), collapsing any thrown error to
`.couldNotDetermine`; `MockCloudKitAccountChecker` is a settable fake.

```swift
import CloudKitAccountChecking

let checker: CloudKitAccountChecking = MockCloudKitAccountChecker(status: .available)
let status = await checker.accountStatus()
```

Kit-level only, and — the second module in this repo needing
`BackgroundTaskScheduling`'s category of reasoning, not a pattern being
avoided but an honest recurring outcome — never real-tested even though it
looks like a safe status read. Verified before building this: calling
`CKContainer.accountStatus()` without the
`com.apple.developer.icloud-services` entitlement (which `QuoteBox` doesn't
have — no natural need for iCloud sync, same reasoning as `LocationAuthorization`)
can crash with an uncatchable `CKException` rather than throwing a normal Swift
error. `QuoteBoxTests/CloudKitAccountCheckingTests.swift` tests only the mock.

### `PurchaseSupport` (Swift Package product)

A `PurchaseManaging` protocol wrapping StoreKit 2's `Product`/`Transaction` APIs.
`StoreKitTest`'s `SKTestSession` is itself a local, offline StoreKit simulator —
built with `disableDialogs = true` specifically to prevent interactive
confirmation UI during automated tests — so `StoreKitPurchaseManager` is exercised
for real against a `.storekit` configuration file, not just a hand-written fake.

```swift
import StoreKitTest
import PurchaseSupport

let session = try SKTestSession(configurationFileNamed: "Configuration")
session.disableDialogs = true

let manager = StoreKitPurchaseManager()
let product = try await manager.product(for: "com.myapp.tip")
let purchased = try await manager.purchase(product!)
```

`MockPurchaseManager` exists for app-logic tests that don't need to touch
StoreKit at all — but `Product` has no public initializer, so unlike the kit's
other fakes it can't fabricate one from nothing. It holds a real `Product`
(typically fetched once via a real `StoreKitPurchaseManager` under
`SKTestSession`) and fakes only the purchase outcome.

`QuoteBox` wires this into a real "Tip Jar" feature (`StoreKitPurchaseManager` in
production, `MockPurchaseManager` under `--mock-success`/`--mock-error`), the same
DI pattern as every other kit-backed dependency in the app. It's validated at the
kit level via `SKTestSession` in `QuoteBoxTests/PurchaseSupportTests.swift`, and
now also through `QuoteBoxUITests`: `project.yml` wires the `QuoteBox` scheme's Run
action to `QuoteBoxTests/Configuration.storekit` via XcodeGen's
`storeKitConfiguration` (the mechanism `SKTestSession` doesn't cover, since a
UI-tested app launches in its own process), so both a manual run and a UI-test
launch resolve StoreKit calls against local test data instead of the real App
Store. A `--real-purchases` launch argument (combined with `--mock-success`, same
shape as `--mock-notifications-denied`) swaps in the real `StoreKitPurchaseManager`
while everything else stays deterministic, so
`testTipJarPurchaseResolvesAgainstWiredStoreKitConfiguration` can tap Tip Jar and
assert the app reaches `.purchasing`/`.purchased` rather than `.failed` — proving
the product actually resolved against the wired config.

That test deliberately stops before the system purchase-confirmation sheet itself:
it's owned by a process outside the app's own accessibility tree, so reliably
tapping through it means resorting to raw coordinate taps, the same class of
fragile, OS-version-dependent hack this kit avoids everywhere else a system-owned
dialog is involved (`LocationAuthorization`'s `.notDetermined` avoidance,
`DeepLinkTesting`'s avoidance of the native "Open in App" confirmation). Also
worth knowing if this flakes in CI: there's a documented Apple Developer Forums
regression on some simulator runtimes where `xcodebuild test` from the CLI (how
`reusable-test.yml` runs everything) doesn't reliably propagate a scheme's
StoreKit configuration to the simulator, even though it works from the Xcode IDE —
unresolved upstream, not something this repo can work around.

A second, separate CI flake in this same area: the "StoreKit Testing in Xcode"
local certificate that ships with a given Xcode install can occasionally fail
signature verification with `Certificate is not temporally valid` — seen on both
this test and `PurchaseSupportTests.testFetchAndPurchaseTipProduct`, on the same
CI run other tests including this one passed cleanly minutes earlier. GitHub's
macOS runner image pins a specific Xcode version per run, and StoreKit's local
testing certificate is scoped to that install; re-running the job is the fix, not
a code change here.

`PurchaseManaging` also covers subscriptions, not just the one-shot tip above:
`isEntitled(to:)` wraps `Transaction.currentEntitlements` (true for a
subscription still in its billing period, or a non-revoked non-consumable),
and `observeTransactionUpdates(_:)` wraps `Transaction.updates` in a
`Task<Void, Never>` the caller owns and cancels — StoreKit's own update
sequence never finishes on its own. `MockPurchaseManager` gains a settable
`isEntitledResult` and a `simulateTransactionUpdate(_:)` test hook, the same
"settable state" shape as every other `Mock*`.

```swift
let isSupporter = await manager.isEntitled(to: "com.myapp.supporter.monthly")
let observation = manager.observeTransactionUpdates { transaction in
    print("Renewed:", transaction.productID)
}
// observation.cancel() when the observing feature goes away
```

`QuoteBox` wires this into a "Become a Supporter" monthly subscription
alongside Tip Jar — same `TipJarStore`, same UI pattern, new
`com.quotebox.supporter.monthly` product in `Configuration.storekit`'s
`subscriptionGroups`. `TipJarStore.refreshSupporterStatus()` calls
`isEntitled(to:)` in the same `.task` that already triggers
`store.fetchNewQuote()`, checking entitlement rather than assuming purchase
success implies an active subscription — a completed purchase can later
lapse (cancellation, billing failure) without the store observing that
renewal event directly. Validated via `SKTestSession` in
`PurchaseSupportTests.testIsEntitledReflectsRealPurchaseUnderTestSession`.

**Scope note**, matching this kit's existing honesty pattern
(`SnapshotTesting`'s and `LocalizationCompletenessChecking`'s scope notes):
this covers one subscription tier exercised locally via `SKTestSession`, not
App Store Server Notifications or receipt/JWS validation against Apple's
servers — this kit has no server component, so a lapsed-and-since-renewed
subscription the app hasn't relaunched to re-check is a gap `isEntitled(to:)`
alone can't close. `observeTransactionUpdates(_:)` narrows that window (it
fires on renewal while the app is running) but doesn't eliminate it.

### `DebugOverlay` (Swift Package product)

A drop-in SwiftUI panel (`DebugOverlayView`) that renders `[DebugSection]` — plain
label/value rows grouped under a title — so a developer can see runtime state
without attaching a debugger. It's deliberately generic: this module has no
dependency on any other module in the kit, the same way `UITestHelpers` stays
generic and lets the consuming app decide what's worth showing. The one thing it
does provide out of the box is `DebugSection.launchArguments()`, since every
kit-backed dependency in this repo already switches behavior on a `--flag` (see
`--mock-success`/`--mock-error`/`--real-purchases`/`--deep-link <url>` throughout
this README) — seeing which ones are active on a running build is otherwise
invisible without re-reading the scheme.

```swift
import DebugOverlay

DebugOverlayView(sections: [
    .launchArguments(),
    DebugSection("Session", rows: [DebugRow("User ID", currentUserID)])
])
```

`QuoteBox` wires this into a `#if DEBUG`-gated "Debug" tab in `RootView` — visible
in every scheme in `project.yml` builds by default, including the one CI's
`xcodebuild test` runs against, so `QuoteBoxUITests/testDebugTabShowsLaunchArgumentsAndAppState`
can assert against it directly — showing launch arguments, the `UserDefaultsStore`-backed
launch count, and `QuoteStore`/`TipJarStore`'s current state (quote state,
favorites count, reminder state, tip jar state), read directly off those stores
rather than re-implemented, so the panel can't drift out of sync with the state
machines it's reporting on.

### `PowerStateProviding` (Swift Package product)

Lets app code ask "is Low Power Mode on?" through an injectable dependency
instead of calling `ProcessInfo.processInfo.isLowPowerModeEnabled` directly,
so a test can force either side of a power-aware code path (reduced polling,
disabled animations) deterministically. `SystemPowerStateProvider` wraps that
read directly — Foundation, not UIKit, so no `@MainActor` bridging is needed
the way `IdleTimerControlling`'s `UIApplication.shared` touchpoint requires.
`MockPowerStateProvider` is a settable fake.

```swift
import PowerStateProviding

let power: PowerStateProviding = MockPowerStateProvider(isLowPowerModeEnabled: true)
```

Also covers thermal state, the same `ProcessInfo` framework's other
power-adjacent read — kept in this module rather than split into a second
one, the same "don't fragment one framework across modules" reasoning
`PurchaseSupport`'s subscription support was added under. `thermalState`/
`startMonitoringThermalState`/`stopMonitoringThermalState` follow
`NetworkReachabilityMonitoring`'s `current<X> { get }` +
`startMonitoring`/`stopMonitoring` shape: `SystemPowerStateProvider` observes
`ProcessInfo.thermalStateDidChangeNotification` via `NotificationCenter`
rather than polling; `MockPowerStateProvider` gets a matching
`simulateThermalStateChange(to:)`.

```swift
power.startMonitoringThermalState { state in print(state) }
```

Kit-level only. Safe to exercise the real provider for real — plain,
synchronous, non-prompting reads, and constructing/tearing down the real
notification observer never prompts or crashes either, even though nothing
in CI can force an actual thermal state change to fire it
(`QuoteBoxTests/PowerStateProvidingTests.swift` does both).

### `BatteryStateProviding` (Swift Package product)

Lets app code ask "how much charge is left, and is the device plugged in?"
through an injectable dependency instead of reading `UIDevice.current`
directly, so a test can force any battery level/charging combination
deterministically (skip a background sync below 20% unplugged, badge a
"charging" indicator). Distinct from `PowerStateProviding`: that wraps
`ProcessInfo` (Low Power Mode, thermal state) — plain Foundation reads with
no `@MainActor` concern; this wraps `UIDevice`, UIKit surface, so methods are
`async` from the start, the same reasoning `IdleTimerControlling`/
`AccessibilityStateProviding` give for their own `UIApplication`/
`UIAccessibility` touchpoints. Keeps `UIDevice.BatteryState` directly
(`.unknown`/`.unplugged`/`.charging`/`.full`), same reasoning every
status-checking module gives for keeping a framework's own type.
`SystemBatteryStateProvider` bridges through `await MainActor.run { ... }`,
the same technique `SystemIdleTimerControl` already established.
`MockBatteryStateProvider` is a settable fake.

```swift
import BatteryStateProviding

let battery: BatteryStateProviding = MockBatteryStateProvider(monitoringEnabled: true, level: 0.42, state: .charging)
```

Reading `batteryLevel()`/`batteryState()` requires monitoring to be enabled
first — `UIDevice` returns `-1.0`/`.unknown` otherwise — so this protocol
exposes `setBatteryMonitoringEnabled(_:)` rather than assuming it's already
on.

Kit-level only. Safe to exercise the real provider for real — toggling
monitoring and reading level/state never prompts or crashes
(`QuoteBoxTests/BatteryStateProvidingTests.swift` does) — but unlike
`IdleTimerControlling`'s equivalent round-trip, the test doesn't assert
`isBatteryMonitoringEnabled()` reads back `true` after being set: the
Simulator has no real battery, and the flag doesn't reliably stick there
(found via a failed CI run).

### `ScreenCaptureStateProviding` (Swift Package product)

Lets app code ask "is the screen being recorded, mirrored, or AirPlayed
right now?" through an injectable dependency instead of reading
`UIScreen.main.isCaptured` directly, so a test can force either side of a
capture-aware code path (blur sensitive content, pause media playback)
deterministically. `UIScreen` is `@MainActor`-isolated, so methods are
`async`, same reasoning `AccessibilityStateProviding`/`IdleTimerControlling`
give for their own UIKit touchpoints. Mirrors `PowerStateProviding`'s
thermal-state shape — a read plus `startMonitoring`/`stopMonitoring`, since
capture state can change mid-session. `SystemScreenCaptureStateProvider`
observes `UIScreen.capturedDidChangeNotification` via `NotificationCenter`
on the main queue; `MockScreenCaptureStateProvider` gets a matching
`simulateScreenCaptureChange(to:)`.

```swift
import ScreenCaptureStateProviding

let screenCapture: ScreenCaptureStateProviding = MockScreenCaptureStateProvider(isCaptured: true)
```

**Scope note:** `UIScreen.isCaptured` is deprecated in Apple's own headers
in favor of `sceneCaptureState` — but that replacement isn't available in
the SDK this kit's own CI actually builds against (Xcode 16.4 / iOS 18.5),
and its exact API surface isn't findable in Apple's public documentation
yet either, the same "can't verify, won't guess" caution
`SwiftDataTestSupport`/`PasskeyAuthentication` were built with instead of
chasing an unconfirmed signature. `isCaptured` still works (iOS 11+, well
under this module's floor) and only emits a compiler deprecation warning,
not a build failure.

Kit-level only. Safe to exercise the real provider for real — reading
`isCaptured` and constructing/tearing down the real notification observer
never prompt or crash, even though nothing in CI can force an actual screen
recording to start and fire it
(`QuoteBoxTests/ScreenCaptureStateProvidingTests.swift` does both).

### `ProtectedDataAvailabilityProviding` (Swift Package product)

Lets app code ask "is file-protected/Keychain data actually accessible
right now?" through an injectable dependency instead of reading
`UIApplication.shared.isProtectedDataAvailable` directly, so a test can
force either side of a protection-aware code path (defer a Keychain read
until after first unlock) deterministically. `false` means the device is
locked and files with `.complete`/`.completeUnlessOpen` data protection
can't be read or written yet. Unlike every other `UIApplication.shared`
touchpoint in this kit, Apple's own headers mark `isProtectedDataAvailable`
`nonisolated` on an otherwise `@MainActor` class — a deliberate exemption,
since it has to be safely readable from any context, including very early
in app launch. So this protocol's read is a plain synchronous function, not
`async` — the one UIKit module in this kit that isn't.
`SystemProtectedDataAvailabilityProvider` monitors both
`protectedDataDidBecomeAvailableNotification` and
`protectedDataWillBecomeUnavailableNotification` via `NotificationCenter`;
`MockProtectedDataAvailabilityProvider` gets a matching
`simulateProtectedDataAvailabilityChange(to:)`.

```swift
import ProtectedDataAvailabilityProviding

let dataProtection: ProtectedDataAvailabilityProviding = MockProtectedDataAvailabilityProvider(isProtectedDataAvailable: false)
```

Kit-level only. Safe to exercise the real provider for real — reading
`isProtectedDataAvailable` and constructing/tearing down the real
notification observers never prompt or crash, but the test deliberately
doesn't assert the value itself is `true`: unlike a real device, nothing
guarantees a CI Simulator's data-protection state during an automated run —
the same caution `BatteryStateProvidingTests` was corrected to use after a
real CI run showed a Simulator-state assumption didn't hold
(`QuoteBoxTests/ProtectedDataAvailabilityProvidingTests.swift`).

### `BundleInfoProviding` (Swift Package product)

Lets app code ask "what version/build is this?" through an injectable
dependency instead of reading `Bundle.main.infoDictionary` directly, so a
test can force a specific version string (a "what's new" screen, a
support-email footer) deterministically. `SystemBundleInfoProvider` wraps
`Bundle.infoDictionary`'s `CFBundleShortVersionString`/`CFBundleVersion`
keys, defaulting to `"unknown"` rather than crashing when a key is missing.
`MockBundleInfoProvider` is a settable fake.

```swift
import BundleInfoProviding

let bundleInfo: BundleInfoProviding = MockBundleInfoProvider(appVersion: "2.3", buildNumber: "42")
```

Kit-level only. Safe to exercise the real provider for real — a plain,
synchronous Foundation read — but
`QuoteBoxTests/BundleInfoProvidingTests.swift` only asserts non-empty, not
exact values, since it reads whatever the test bundle's own Info.plist
reports rather than a fixed value.

### `CellularDataRestrictionChecking` (Swift Package product)

Lets app code ask "has the user restricted this app from cellular data?"
(Settings > Cellular's per-app toggle) through an injectable dependency.
Uses `CTCellularDataRestrictedState` directly, same reasoning every other
module here gives for keeping a framework's own status type.
`SystemCellularDataChecker` wraps `CTCellularData().restrictedState` — no
entitlement required (verified before writing this module — unlike most
CoreTelephony APIs, `CTCellularData` doesn't need one), available since iOS 9.
`MockCellularDataChecker` is a settable fake.

```swift
import CellularDataRestrictionChecking

let checker: CellularDataRestrictionChecking = MockCellularDataChecker(state: .restricted)
```

Kit-level only. The real checker's status read is exercised for real in
`QuoteBoxTests/CellularDataRestrictionCheckingTests.swift` — expected to be
safe given no entitlement is required, though a fresh Simulator with no
cellular hardware may just report `.restrictedStateUnknown` rather than a
real value.

### `DiskSpaceChecking` (Swift Package product)

Lets app code ask "how much disk space is available/does this device have
in total?" through an injectable dependency instead of reading
`URLResourceValues`' volume capacity keys directly, so a test can force a
low-space scenario (skip a cache prefetch, warn before a large download)
deterministically. Plain, synchronous Foundation reads, not UIKit, so no
`@MainActor` bridging is needed — same reasoning `PowerStateProviding`/
`BundleInfoProviding` give for their own Foundation-only touchpoints.
`SystemDiskSpaceChecker` wraps `URL.resourceValues(forKeys:)` against the
app's home directory, `try?`-collapsing failure to `nil` rather than
throwing — a disk space check failing shouldn't itself crash or propagate
an error, the same fail-soft reasoning `BundleInfoProviding` gives for
defaulting to `"unknown"`. `availableCapacity()` wraps
`volumeAvailableCapacityForImportantUsage` rather than the plainer
`volumeAvailableCapacity` — Apple's own guidance is that the "important
usage" key is the one to check before an operation the user actually asked
for, since it accounts for space the system might reclaim from
purgeable/opportunistic data. `MockDiskSpaceChecker` is a settable fake.

```swift
import DiskSpaceChecking

let diskSpace: DiskSpaceChecking = MockDiskSpaceChecker(available: 1_000_000, total: 64_000_000_000)
```

Kit-level only. Safe to exercise the real checker for real — a plain,
synchronous, non-prompting read against the app's own home directory —
but `QuoteBoxTests/DiskSpaceCheckingTests.swift` only asserts the values
are positive and internally consistent (`available <= total`), not exact
figures, since the real numbers depend entirely on the CI Simulator host's
actual disk state.

### `AccessibilityStateProviding` (Swift Package product)

Lets app code ask "is VoiceOver/Reduce Motion on?" through an injectable
dependency instead of reading `UIAccessibility` directly, so a test can
force either side of an accessibility-aware code path (skip an animation,
announce state changes) deterministically. Methods are `async` from the
start, not because the underlying reads are slow, but because
`UIAccessibility`'s properties are UIKit and recent SDKs increasingly mark
UIKit surface `@MainActor` — same reasoning `SystemReviewRequester` already
established for `UIApplication.shared` in this repo, applied proactively
here rather than discovered via a build failure.
`SystemAccessibilityStateProvider` bridges `UIAccessibility.isVoiceOverRunning`/
`.isReduceMotionEnabled` through `await MainActor.run { ... }`.
`MockAccessibilityStateProvider` is a settable fake.

```swift
import AccessibilityStateProviding

let accessibility: AccessibilityStateProviding = MockAccessibilityStateProvider(voiceOverRunning: true)
let voiceOverOn = await accessibility.isVoiceOverRunning()
```

Kit-level only. Safe to exercise the real provider for real — `UIAccessibility`
reads never prompt or crash
(`QuoteBoxTests/AccessibilityStateProvidingTests.swift` does).

### `HapticFeedbackProviding` (Swift Package product)

Lets app code trigger haptic feedback through an injectable dependency
instead of constructing `UIImpactFeedbackGenerator` directly, so a test can
assert "did my code fire the right haptic" without depending on real
hardware (haptics silently no-op on the Simulator). `async` for the same
`@MainActor`-proofing reason `AccessibilityStateProviding` is.
`SystemHapticFeedbackProvider` bridges
`UIImpactFeedbackGenerator(style:).impactOccurred()` through
`await MainActor.run { ... }`. `MockHapticFeedbackProvider` records every
requested style in `[UIImpactFeedbackGenerator.FeedbackStyle]`.

```swift
import HapticFeedbackProviding

let haptics: HapticFeedbackProviding = MockHapticFeedbackProvider()
await haptics.impact(style: .light)
```

Kit-level only. Safe to exercise the real provider for real — no crash on
the Simulator, just a silent no-op
(`QuoteBoxTests/HapticFeedbackProvidingTests.swift` does).

### `IdleTimerControlling` (Swift Package product)

Lets app code disable/re-enable the screen-lock idle timer through an
injectable dependency instead of touching `UIApplication.shared` directly (a
video player, a long-running scan flow). `async` for the same reason
`AccessibilityStateProviding`/`HapticFeedbackProviding` are —
`UIApplication.shared.isIdleTimerDisabled` is exactly the touchpoint
`SystemReviewRequester` already had to defer into a `@MainActor` context for
in this repo, applied here from the start. `SystemIdleTimerControl` bridges
the get/set through `await MainActor.run { ... }`. `MockIdleTimerControl` is
a settable fake.

```swift
import IdleTimerControlling

let idleTimer: IdleTimerControlling = MockIdleTimerControl()
await idleTimer.setIdleTimerDisabled(true)
```

Kit-level only. Safe to exercise the real control for real — set then read
back round-trips cleanly against the real `UIApplication.shared`, with no
persistent side effect beyond the test process's lifetime
(`QuoteBoxTests/IdleTimerControllingTests.swift` does).

### `RemindersAuthorization` (Swift Package product)

Sibling to `CalendarAuthorization`, same `EventKit` framework, different
entity type (`.reminder`, not `.event`). Uses `EKAuthorizationStatus`
directly. `SystemRemindersAuthorizer` — `@available(iOS 17.0, *)`, same shape
as `SystemCalendarAuthorizer`: `requestFullAccessToReminders()` is already a
native `async throws` API, no completion-handler bridging needed (confirmed
via WebSearch before writing this: same iOS 17+ shape as
`requestFullAccessToEvents()`, no entitlement quirk beyond the usual
usage-description key). `MockRemindersAuthorizer` mirrors
`MockCalendarAuthorizer`.

```swift
import RemindersAuthorization

let authorizer: RemindersAuthorizing = MockRemindersAuthorizer(status: .fullAccess)
let granted = await authorizer.requestAccess()
```

Kit-level only, no `NSRemindersFullAccessUsageDescription` key in
`Info.plist` — `QuoteBoxTests/RemindersAuthorizationTests.swift` reads
status only, matching `CalendarAuthorizationTests`' already-proven treatment.

### `LiveActivityAuthorization` (Swift Package product)

No explicit request API — the user manages Live Activities via Settings, not
an in-app prompt, same structural shape as `MotionAuthorizing`/
`BluetoothAuthorizing`. `ActivityAuthorizationInfo` itself is `@available(iOS
16.1, *)` in Apple's headers (confirmed via WebSearch before writing this) —
newer than the package's iOS 13 floor, so the protocol,
`SystemLiveActivityAuthorizer`, AND `MockLiveActivityAuthorizer` are all
annotated from the start, the same class of fix `BluetoothAuthorizing`
needed for `CBManagerAuthorization`. `SystemLiveActivityAuthorizer` reads
`ActivityAuthorizationInfo().areActivitiesEnabled` — no entitlement, no
prompt.

```swift
import LiveActivityAuthorization

let authorizer: LiveActivityAuthorizing = MockLiveActivityAuthorizer(areActivitiesEnabled: true)
```

Kit-level only. Safe to exercise the real authorizer for real
(`QuoteBoxTests/LiveActivityAuthorizationTests.swift` does).

### `ClipboardProviding` (Swift Package product)

Lets app code copy to/read from the system clipboard through an injectable
dependency instead of touching `UIPasteboard` directly, so a test can assert
"did my code copy the right string." `SystemClipboardProvider` wraps
`UIPasteboard.general.string` (get/set) — deliberately kept synchronous,
unlike `AccessibilityStateProviding`/`HapticFeedbackProviding`/
`IdleTimerControlling`: `UIPasteboard` is documented by Apple as safe to use
off the main thread (designed for cross-process access, unlike most UIKit
surface), so it hasn't picked up the same `@MainActor` isolation those other
UIKit types have. `MockClipboardProvider` is a settable fake.

```swift
import ClipboardProviding

let clipboard: ClipboardProviding = MockClipboardProvider()
clipboard.copy("hello")
```

Kit-level only. Safe to exercise the real provider for real — a copy/read
round trip against the real Simulator pasteboard has no lasting side effect
worth avoiding (`QuoteBoxTests/ClipboardProvidingTests.swift` does).

### `FocusStatusAuthorization` (Swift Package product)

Same protocol+real+fake shape as `SiriAuthorization`. Uses
`INFocusStatusAuthorizationStatus` directly.
`INFocusStatusCenter`/`INFocusStatusAuthorizationStatus` is `@available(iOS
15.0, *)` (confirmed via WebSearch before writing this), annotated on the
protocol, mock, AND system class from the start. `SystemFocusStatusAuthorizer`
wraps `INFocusStatusCenter`: `requestAuthorization(_:)` is a plain completion
handler, bridged to `async` via `CheckedContinuation` — same shape as
`SystemSiriAuthorizer`. `MockFocusStatusAuthorizer` is a settable fake.

```swift
import FocusStatusAuthorization

let authorizer: FocusStatusAuthorizing = MockFocusStatusAuthorizer(status: .authorized)
let result = await authorizer.requestAuthorization()
```

`INFocusStatusCenter` is in the same Intents-framework family as
`INPreferences` (Siri) and requires the "Communication Notifications"
capability just to use the class — same "documented risk, untested real
path" treatment `SiriAuthorizationTests` already learned to give
`INPreferences`, applied here proactively:
`QuoteBoxTests/FocusStatusAuthorizationTests.swift` only constructs
`SystemFocusStatusAuthorizer()`, never calls a method on it for real.

### `FamilyControlsAuthorization` (Swift Package product)

Wraps Screen Time's `AuthorizationCenter`. Uses `AuthorizationStatus`
directly — a top-level type in the `FamilyControls` module, not nested
inside `AuthorizationCenter` despite `authorizationStatus` being one of its
properties (a real compile failure caught this wrong assumption, not
something verified in advance — fixed here). The `FamilyControls`
framework is `@available(iOS 16.0, *)`, annotated on the protocol, mock, AND
system class from the start. `SystemFamilyControlsAuthorizer` wraps
`AuthorizationCenter.shared`: `requestAuthorization(for:)` is already a
native `async throws` API (unlike Siri/Focus Status's completion-handler
shape) — any thrown error collapses to `false`, the same "collapse thrown
error" pattern `CloudKitAccountChecking` uses for `CKContainer.accountStatus()`.
`MockFamilyControlsAuthorizer` is a settable fake.

```swift
import FamilyControlsAuthorization

let authorizer: FamilyControlsAuthorizing = MockFamilyControlsAuthorizer(status: .approved)
```

Requires the privileged `com.apple.developer.family-controls` entitlement
(confirmed via WebSearch — Apple approval required to ship, an even
stricter tier than `HealthAuthorization`'s entitlement) — QuoteBox doesn't
have it. Treated with `HealthAuthorization`/`CloudKitAccountChecking`'s most
conservative test caution as a result:
`QuoteBoxTests/FamilyControlsAuthorizationTests.swift` only constructs
`SystemFamilyControlsAuthorizer()`, genuinely uncertain whether even the
status read would be crash-safe without the entitlement (unlike Siri/Focus
Status, `requestAuthorization` here is `async throws` rather than a
hard-crashing call, so the failure mode might differ) — defaulting to the
conservative option rather than guessing.

### `JSONFixtureLoading` (Swift Package product)

Not a protocol+real+fake module — there's nothing to fake, it's already a
pure, deterministic function, same "single-purpose utility" shape as
`SnapshotTesting`/`DeepLinkTesting`. Complements `NetworkStub`'s canned HTTP
responses with canned local JSON fixtures for tests that need realistic
decoded data without a network round trip at all.

```swift
import JSONFixtureLoading

struct SampleQuote: Decodable { let text: String }

let quote = try JSONFixtureLoading.load("sample-quote", as: SampleQuote.self, bundle: Bundle(for: Self.self))
```

`JSONFixtureLoading.load(_:as:bundle:decoder:)` looks up `"\(name).json"` in
the given bundle and decodes it, throwing `FixtureLoadingError.fixtureNotFound(name)`
if the resource is missing. Validated against a real fixture file checked
into the repo (`QuoteBoxTests/Fixtures/sample-fixture.json`, wired into
`project.yml`'s `QuoteBoxTests` `resources:`) in
`QuoteBoxTests/JSONFixtureLoadingTests.swift`.

### `LocalizationCompletenessChecking` (Swift Package product)

A single-file utility, same shape as `JSONFixtureLoading`/`SnapshotTesting`
— nothing to fake, no system framework to wrap, just a pure deterministic
function operating on a `.xcstrings` String Catalog the calling project
already has. Complements `SnapshotTesting`'s `locale:` parameter rather than
overlapping it: that renders a view under a specific `Locale` and compares
pixels, but can only catch a bug if a translation *already exists and got
loaded*. This checks one layer earlier — whether a translation was ever
written at all — catching "nobody ever translated this key" before a
snapshot test would ever surface it visually.

```swift
import LocalizationCompletenessChecking

let missing = try LocalizationCompletenessChecking.missingTranslations(
    inCatalogAt: catalogURL,
    for: ["en", "es", "fr"]
)
// [MissingLocalization(key: "Settings", locale: "fr"), ...]
```

Reads the catalog with `JSONSerialization` into loose `[String: Any]`
dictionaries rather than strict `Decodable` structs, since a String
Catalog's `variations` shape (plural categories, device variants) isn't
being modeled — a loose dictionary walk is more robust to catalog-format
drift across Xcode versions than a brittle typed model would be. **Scope
note**, matching this kit's existing honesty pattern (`SnapshotTesting`'s
own scope note, `FeatureFlagging`'s "not a remote-config client" note):
this checks that a locale has *some* translated content for a key (a
`stringUnit` with `state: "translated"`, or a `variations` block present at
all), not that every plural category within a `variations` block is
individually translated — catching "this locale was never touched" covers
the common real bug without hand-rolling a schema for Apple's
plural-category/device-variant shape.

Kit-level only — QuoteBox has no String Catalog of its own. Validated
against a real fixture checked into the repo
(`QuoteBoxTests/Fixtures/sample-catalog.json` — deliberately named `.json`,
not `.xcstrings`, so Xcode's build system doesn't treat it as a real String
Catalog resource to compile; wired into `project.yml`'s `QuoteBoxTests`
`resources:` the same way `sample-fixture.json` is) in
`QuoteBoxTests/LocalizationCompletenessCheckingTests.swift` — no
permission/crash-risk caution needed anywhere here, it's pure file I/O and
JSON parsing.

### `WidgetTimelineTesting` (Swift Package product)

Bridges WidgetKit's completion-handler-based timeline provider to `async` —
the same category of value `SystemSleeper` provides over raw `Task.sleep`:
`getTimeline(in:completion:)` predates Swift concurrency and has no `async`
variant of its own. Deliberately doesn't constrain to Apple's own
`TimelineProvider` protocol: `TimelineProviderContext` has no public
initializer (the same "framework type with no public init" problem
`MockPurchaseManager`'s doc comment documents for StoreKit's `Product`), so
a test could never construct one to drive a real `TimelineProvider` with.
`TimelineProviding` here is structurally equivalent instead, with a generic
`Context` associated type — a real widget's provider satisfies it with a
one-line added conformance, while a test passes a lightweight local
`Context` type it can actually construct.

```swift
import WidgetTimelineTesting

let timeline = await WidgetTimelineTesting.collectTimeline(from: provider, in: context)
XCTAssertEqual(timeline.entries.count, 3)
```

**Scope note**, matching this kit's existing honesty pattern
(`SnapshotTesting`'s and `LocalizationCompletenessChecking`'s scope notes):
QuoteBox has no widget extension target. A real one was evaluated and
deferred — it would need a new XcodeGen `app-extension` target, a
widgetkit-extension `Info.plist`, and an App Group entitlement to share
data with the host app, a materially bigger lift than any other module in
this kit for a demo app whose job is exercising kit modules, not shipping a
widget feature. Kit-level only as a result, but not thinly so:
`QuoteBoxTests/WidgetTimelineTestingTests.swift` drives a dummy provider
whose data source is real — it reads from the same `CoreDataFavoritesStore`
fixture `CoreDataFavoritesStoreTests.swift` already uses, so timeline
entries reflect real (test) favorite-quote data even though nothing renders
them as widget UI.

### `HomeKitAuthorization` (Swift Package product)

No explicit request API — HomeKit prompts implicitly on first real use, same
structural shape as `MotionAuthorizing`/`BluetoothAuthorizing`.
`HMHomeManagerAuthorizationStatus` is this kit's first `OptionSet` status
type — every other module keeps a plain enum. "Not determined" is the
**empty set `[]`**, not a named case (confirmed against the actual header
before writing this: three members — `.determined`, `.restricted`,
`.authorized` — no `.notDetermined`). `SystemHomeKitAuthorizer` deliberately
does **not** hold `HMHomeManager` as an eager stored property the way
`SystemHealthAuthorizer`/`SystemCalendarAuthorizer` hold
`HKHealthStore`/`EKEventStore` — HomeKit is documented to crash on first
*use* without `NSHomeKitUsageDescription` in `Info.plist`, and merely
constructing `HMHomeManager` may itself count as that use, so it's
constructed lazily inside the method body instead.
`MockHomeKitAuthorizer` is a settable fake defaulting to `[]`.

```swift
import HomeKitAuthorization

let authorizer: HomeKitAuthorizing = MockHomeKitAuthorizer(status: .authorized)
```

Kit-level only, treated with `HealthAuthorization`/`FamilyControlsAuthorization`'s
most conservative test caution: QuoteBox has neither
`NSHomeKitUsageDescription` nor the `com.apple.developer.homekit`
entitlement, so `QuoteBoxTests/HomeKitAuthorizationTests.swift` only
constructs `SystemHomeKitAuthorizer()` — which, thanks to the lazy
construction above, never touches HomeKit at all — and never calls
`currentAuthorizationStatus()` on it for real.

### `WatchConnectivityStateProviding` (Swift Package product)

No permission concept at all, unlike every authorization module in this kit
— `WatchConnectivity` never prompts. Lets app code ask "is a Watch
paired/does it have our app?" through an injectable dependency.
`SystemWatchConnectivityStateProvider` wraps `WCSession`: `WCSession` isn't
supported on every device this kit's CI matrix runs against (confirmed via
WebSearch — notably unsupported on iPad), so every access guards with
`WCSession.isSupported()` first and never force-touches `.default` on an
unsupported device — that's the actual crash risk here, not a permission
prompt. `MockWatchConnectivityStateProvider` is a settable fake (three
independent `Bool`s).

```swift
import WatchConnectivityStateProviding

let watch: WatchConnectivityStateProviding = MockWatchConnectivityStateProvider(paired: true)
```

Kit-level only. Safe to exercise the real provider for real on every CI
device, including iPad — expected to gracefully report `isSupported() == false`
there rather than crash
(`QuoteBoxTests/WatchConnectivityStateProvidingTests.swift` does).

### A note on frameworks this kit doesn't cover

Not every system framework fits this kit's pattern — a real,
non-prompting status read a `System*` implementation can safely expose.
**CarPlay, MultipeerConnectivity, and Core NFC were evaluated and excluded**,
the same way earlier rounds ruled out Local Network privacy: CarPlay has no
runtime permission system at all (app approval happens via a special Apple
entitlement at review time, not a user-facing prompt — nothing for a
protocol to model); MultipeerConnectivity's Local Network permission has no
official status API Apple has ever exposed (the only workarounds are hacky
network probes, not a pattern used anywhere else in this kit); Core NFC has
the same gap — no authorization-status read exists. Forcing a module onto
any of these three would mean faking a capability this kit doesn't actually
have, rather than documenting the gap honestly.

### Reusable GitHub Actions workflows

`.github/workflows/reusable-test.yml` runs `xcodebuild test` across a matrix of
simulators, reports code coverage, and uploads the `.xcresult`. Call it from any
repo:

```yaml
jobs:
  test:
    uses: EmilioBejasa/iOS_testing_suite/.github/workflows/reusable-test.yml@v1.4.0
    with:
      scheme: MyApp
      project: MyApp.xcodeproj
      devices: '["iPhone 16", "iPad (10th generation)"]'
      skip_testing: "MyAppTests/LiveContractTests"
```

`.github/workflows/reusable-live-contract.yml` runs a single test identifier
against a real network on a schedule, kept separate so a live API hiccup can't
block a PR:

```yaml
on:
  schedule:
    - cron: "0 13 * * *"

jobs:
  contract:
    uses: EmilioBejasa/iOS_testing_suite/.github/workflows/reusable-live-contract.yml@v1.4.0
    with:
      scheme: MyApp
      project: MyApp.xcodeproj
      only_testing: "MyAppTests/LiveContractTests"
```

Both workflows assume XcodeGen by default (`xcodegen: true`); pass `xcodegen: false`
if your project already checks in an `.xcodeproj`.

## The QuoteBox app

Everything under `QuoteBox/`, `QuoteBoxTests/`, and `QuoteBoxUITests/` is a working
consumer of the above: `project.yml` pulls in this same repo as a local Swift
package (`packages: iOSTestKit: path: .`), and `.github/workflows/ci.yml` /
`live-api-contract.yml` call the reusable workflows with QuoteBox-specific inputs.
Any other app would do the same thing from its own repo, pointing `.package(url:)`
at a tagged release of this one instead of a local path.

### Running the kit's own tests

Three run paths, depending on what you're testing:

```sh
make test-kit      # swift test — the macOS-runnable subset of kit-only modules,
                    # no XcodeGen/Xcode project needed at all
make test-kit-ios   # xcodebuild against the bare Package.swift on an iOS Simulator —
                    # covers the remaining kit-only modules whose Sources/ import an
                    # iOS-only framework (UIKit, HealthKit, etc.), still no QuoteBox
                    # app or XcodeGen needed
make test-app       # xcodebuild against the generated QuoteBox.xcodeproj — the 8
                    # app-dependent tests plus QuoteBoxUITests
```

CI runs all three (`swift-test`, `kit-tests-ios`, and the existing `test` job) plus
a SwiftLint pass on every push/PR to `master` — see `.github/workflows/ci.yml`.

## More

- [CHANGELOG.md](CHANGELOG.md) — what changed in each tagged version.
- [CONTRIBUTING.md](CONTRIBUTING.md) — how to add a module, run tests locally,
  and what a PR is expected to include.
- [LICENSE](LICENSE) — MIT.
