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
