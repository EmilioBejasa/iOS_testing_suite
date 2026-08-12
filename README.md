# iOS Test Kit

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

## What's reusable

### `NetworkStub` (Swift Package product)

`URLProtocolStub` intercepts requests on a configured `URLSession` so any
`URLSession`-based network client can be tested against canned responses. The only
requirement on the app side is that the client accepts an injectable `URLSession`.

```swift
.package(url: "https://github.com/EmilioBejasa/iOS_testing_suite", from: "1.1.0")
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
plain unit test (no simulator UI interaction, no XCUITest involved).

`assertSnapshot` also takes optional `locale:`/`dynamicTypeSize:` parameters,
defaulting to `nil` so every existing call site (QuoteBox's included) renders
exactly as before:

```swift
assertSnapshot(of: MyView(), dynamicTypeSize: .accessibility3, named: "loaded-accessibility3")
```

This replaces relying on an accessibility audit's allow-listed exception with
actually rendering and comparing the larger size — no automatic filename
suffixing, the caller names each variant explicitly via `named:`, same as today.
**Scope note:** this round ships the capability only; it isn't accompanied by a
new committed reference image for `QuoteBox` itself. Recording one needs
`SNAPSHOT_RECORD=1` run on a Mac with Xcode/Simulator, which wasn't available
while building this — a real gap, not a hidden one.

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

Kit-level only. Safe to exercise the real provider for real — a plain,
synchronous, non-prompting read
(`QuoteBoxTests/PowerStateProvidingTests.swift` does).

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

### Reusable GitHub Actions workflows

`.github/workflows/reusable-test.yml` runs `xcodebuild test` across a matrix of
simulators, reports code coverage, and uploads the `.xcresult`. Call it from any
repo:

```yaml
jobs:
  test:
    uses: EmilioBejasa/iOS_testing_suite/.github/workflows/reusable-test.yml@v1.1.0
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
    uses: EmilioBejasa/iOS_testing_suite/.github/workflows/reusable-live-contract.yml@v1.1.0
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
