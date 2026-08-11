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
.package(url: "https://github.com/EmilioBejasa/iOS_testing_suite", from: "1.0.0")
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

### Reusable GitHub Actions workflows

`.github/workflows/reusable-test.yml` runs `xcodebuild test` across a matrix of
simulators, reports code coverage, and uploads the `.xcresult`. Call it from any
repo:

```yaml
jobs:
  test:
    uses: EmilioBejasa/iOS_testing_suite/.github/workflows/reusable-test.yml@v1.0.0
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
    uses: EmilioBejasa/iOS_testing_suite/.github/workflows/reusable-live-contract.yml@v1.0.0
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
