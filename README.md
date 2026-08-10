# iOS Test Kit

A reusable iOS testing setup — a Swift package of test helpers, plus GitHub Actions
workflows any iOS repo can call by reference instead of copy-pasting CI config.

> **This branch (`verify-portability-quotebox`) exists to verify the kit is genuinely
> app-agnostic.** It swaps out `master`'s Weather demo app for QuoteBox: a
> different domain (DummyJSON quotes, not Open-Meteo weather), a different
> architecture (`@Observable` + `TabView`, not `ObservableObject` MVVM +
> `NavigationStack` list/detail), and a different testing surface (adds local
> UserDefaults-backed persistence, not just network). Same `NetworkStub` /
> `UITestHelpers` package, same `reusable-test.yml` / `reusable-live-contract.yml`,
> unmodified. It's not meant to be merged into `master` — `master` keeps Weather.

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

## The QuoteBox app (this branch)

Everything under `QuoteBox/`, `QuoteBoxTests/`, and `QuoteBoxUITests/` is a working
consumer of the above: `project.yml` pulls in this same repo as a local Swift
package (`packages: iOSTestKit: path: .`), and `.github/workflows/ci.yml` /
`live-api-contract.yml` call the reusable workflows with QuoteBox-specific inputs.
Compare these two files with `master`'s versions — same reusable workflow files,
different `with:` inputs — to see exactly what changes per app and what doesn't.
