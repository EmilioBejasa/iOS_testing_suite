# Contributing

## Adding a new module

Most modules in `Sources/` follow the same three-file shape:

- `<Name>ing.swift` (or similar) — a protocol describing the capability, kept
  narrow to what a consumer actually needs.
- `System<Name>.swift` — the real implementation, wrapping the system
  framework. Only exposes non-prompting status reads it can safely provide;
  see the README's "note on frameworks this kit doesn't cover" for the line
  this kit draws.
- `Mock<Name>.swift` — an in-memory fake for tests, with settable state and
  no dependency on the real framework.

A handful of modules are single-file utilities instead (`JSONFixtureLoading`,
`LocalizationCompletenessChecking`, `DeepLinkTesting`) — pure, deterministic
functions with nothing to fake. Use this shape only when there's genuinely no
system framework or stateful behavior to abstract.

To add a module:

1. Create `Sources/<ModuleName>/` with the files above.
2. Add the product and target to `Package.swift`, matching an existing
   entry's shape.
3. Add tests, in one of two places depending on what the module touches:
   - **Kit-only** (no `@testable import QuoteBox`, no app types): add
     `Tests/<ModuleName>Tests/<ModuleName>Tests.swift` and a matching
     `.testTarget` entry in `Package.swift`. If the module's `Sources/`
     imports an iOS-only framework (UIKit, HealthKit, etc.), wrap the
     *entire* test file body in `#if os(iOS) ... #endif` - matching the same
     guard already on the module's `Sources/` files - so it still builds, as
     an empty target, under plain `swift test` on macOS; it'll only run real
     assertions via `xcodebuild test -scheme iOSTestKit-Package -destination
     'platform=iOS Simulator,name=...'` (Xcode auto-synthesizes that scheme
     name, `<PackageName>-Package`, for a bare `Package.swift` with no
     checked-in `.xcodeproj`). Use `#if os(iOS)`, not
     `#if canImport(Framework)`: several frameworks a module might import
     (CoreMotion, Intents) resolve fine on macOS as a module - just missing
     the specific type this kit needs - so `canImport` alone would evaluate
     true and still fail to compile there.
   - **App-dependent** (needs `@testable import QuoteBox` or another app
     type): add `QuoteBoxTests/<ModuleName>Tests.swift`, the way
     `MemoryLeakDetectionTests` does.

   Either way, document why a module is kit-level only if it doesn't get
   exercised through QuoteBox, the way `LocalizationCompletenessChecking`
   does.
4. Add a `### \`ModuleName\`` section to the README, in the themed group it
   belongs to in the table of contents — body order should match TOC order.
   Mirror the module's doc comment closely; this kit keeps source doc
   comments and README prose in sync rather than treating them as separate
   writeups.
5. If the module has a deliberate limitation, call it out explicitly with a
   **Scope note**, the way `SnapshotTesting` and `LocalizationCompletenessChecking`
   do — this kit prefers documenting a gap honestly over silently under-covering it.

## Running tests locally

`make setup` (or `./Scripts/setup.sh`) installs XcodeGen via Homebrew if
needed and runs `xcodegen generate` — do this once, or whenever `project.yml`
changes.

From there, which command to run depends on what you're testing:

```sh
make test-kit      # swift test — the macOS-runnable kit-only modules, no
                    # Xcode project needed at all (fastest feedback loop)
make test-kit-ios   # xcodebuild against the bare Package.swift on an iOS
                    # Simulator — covers the kit-only modules whose Sources/
                    # import an iOS-only framework (see the module-authoring
                    # decision tree above); still no QuoteBox app needed
make test-app       # xcodebuild against QuoteBox.xcodeproj — the 8
                    # app-dependent tests plus QuoteBoxUITests
make lint           # swiftlint lint --strict
```

`make test-app` excludes `DummyJSONLiveContractTests` (it hits a real network
API and runs on a schedule via `.github/workflows/live-api-contract.yml`
instead). CI (`.github/workflows/ci.yml`) runs all of the above — `test`
(the `make test-app` suite across a device matrix), `swift-test`,
`kit-tests-ios`, and `lint` — on every push and PR to `master`.

**Configuration.storekit is duplicated**, not shared, between
`Tests/PurchaseSupportTests/` and `Tests/AsyncSequenceCollectingTests/`: SwiftPM
resources must live inside the target that references them, so a single file
can't be pointed at from two test targets. If you need to change the StoreKit
test configuration, update both copies.

**Real `SKTestSession` purchases don't work under `make test-kit`/`make
test-kit-ios`**: `testFetchAndPurchaseTipProduct`,
`testIsEntitledReflectsRealPurchaseUnderTestSession`, and
`testCollectsRealTransactionUpdateAfterExternalPurchase` are skipped in both
CI jobs (and worth skipping locally too) - StoreKit product lookup failed
consistently, not intermittently, when driven from a bare `swift
test`/`xcodebuild test -scheme iOSTestKit-Package` process with no app/test-host
bundle context, unlike `reusable-test.yml`'s `test` job which hosts these
inside a real Xcode-built `.xctest` bundle. Mock-backed coverage
(`MockPurchaseManager`) still runs everywhere; the real-session path stays
covered by `QuoteBoxUITests`'
`testTipJarPurchaseResolvesAgainstWiredStoreKitConfiguration`.

No Mac available? `.github/workflows/record-snapshots.yml` runs
`SNAPSHOT_RECORD=1` for a single test identifier on a `macos-15` runner and
uploads the resulting reference image as a build artifact — dispatch it from
the Actions tab (or `gh workflow run record-snapshots.yml -f
scheme=QuoteBox -f project=QuoteBox.xcodeproj -f
only_testing=QuoteBoxTests/YourTest`), download the artifact, and commit the
PNG under the matching `__Snapshots__/` path.

## Pull requests

- Keep one module or fix per PR where practical — the module-per-PR history
  in `git log` is what the CHANGELOG entries are built from.
- Bump the version references (README's `.package(url:from:)` example,
  `CHANGELOG.md`) in a dedicated PR when cutting a release, rather than
  folding a version bump into a feature PR.
