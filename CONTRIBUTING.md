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
     an empty target, under plain `swift test` on macOS. See
     [Troubleshooting](#troubleshooting-swiftpm-kit-only-tests) for why
     `#if os(iOS)`, not `#if canImport(Framework)`, and for any `@available`
     floor the test file may also need.
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
`kit-tests-ios`, and `lint` — on every push and PR to `master`. If
`make test-kit`/`make test-kit-ios` fail or behave oddly, check
[Troubleshooting](#troubleshooting-swiftpm-kit-only-tests) first — most of
what's there was hit and fixed while first setting these two up.

No Mac available? `.github/workflows/record-snapshots.yml` runs
`SNAPSHOT_RECORD=1` for a single test identifier on a `macos-15` runner and
uploads the resulting reference image as a build artifact — dispatch it from
the Actions tab (or `gh workflow run record-snapshots.yml -f
scheme=QuoteBox -f project=QuoteBox.xcodeproj -f
only_testing=QuoteBoxTests/YourTest`), download the artifact, and commit the
PNG under the matching `__Snapshots__/` path.

## Troubleshooting: SwiftPM kit-only tests

Everything below was hit — and fixed — while first setting up `swift test`
and `xcodebuild test -scheme iOSTestKit-Package` for the kit-only test
targets under `Tests/`. If you're adding a new kit-only module or its test
starts failing in a way that looks environmental rather than a real bug,
check here before digging further.

**The scheme is `iOSTestKit-Package`, not `iOSTestKit`.** Xcode
auto-synthesizes a scheme named `<PackageName>-Package` for a bare
`Package.swift` with no checked-in `.xcodeproj` — `xcodebuild -list` against
the repo root confirms the exact name if this ever changes.

**Use `#if os(iOS)`, not `#if canImport(Framework)`, to guard an iOS-only
module's test file (and Sources files, if needed).** Most iOS-only
frameworks (UIKit, HealthKit, CoreTelephony, MediaPlayer, ActivityKit,
BackgroundTasks, WatchConnectivity, FamilyControls, MetricKit, HomeKit) don't
exist on macOS at all, so `canImport` correctly evaluates false there. But a
few (CoreMotion, Intents) *do* resolve as importable on macOS — just missing
the specific type the module needs (`CMMotionActivityManager`,
`INSiriAuthorizationStatus`) — so `canImport` evaluates true, compiles the
guarded code anyway, and fails on the missing symbol instead of skipping it
cleanly. `#if os(iOS)` doesn't depend on knowing each framework's exact
macOS module-vs-symbol availability; it's unconditionally false on macOS
regardless.

**A test file may need its own `@available(iOS X.Y, *)`, separate from its
Sources module's.** This package's own floor is iOS 13 / macOS 13
(`Package.swift`). Any System*/Mock* type — or free function — annotated
with a higher floor needs that *same* floor repeated on the test file's
class or method that references it, or the build fails for whichever
platform doesn't meet it. Two specific traps:
- **The iOS 17 / macOS 14 pairing**: Apple ships some APIs (SwiftData, the
  granular EventKit access methods, XCTest's accessibility audit) as an
  iOS 17 **and** macOS 14 pair. Since this package's macOS floor is only 13,
  code marked `@available(iOS 17.0, *)` alone compiles fine for iOS but
  fails on macOS unless `macOS 14.0` is added explicitly.
- **Use the *highest* floor actually referenced**, not just the first one
  you notice — e.g. a file that both calls `SKTestSession.buyProduct`
  (iOS 17) and something needing only iOS 14 needs `@available(iOS 17.0, *)`
  on the whole scope, not 14.

**Use `Bundle.module`, not `Bundle(for: SomeClass.self)`, to load a test
target's own copied resources.** `Bundle(for:)` works under Xcode's
one-bundle-per-test-target model, but `swift test` links every target into
a single runner executable, so it doesn't reliably resolve to the specific
target's resource bundle. `Bundle.module` is SwiftPM's generated accessor
for a target's own `resources:` and is correct in both environments.

**`SKTestSession(configurationFileNamed:)` doesn't find
`Configuration.storekit` under `swift test`** — same root cause as the
`Bundle.module` issue above: it searches the process's main bundle, which
isn't this target's resource bundle here. Resolve the file via
`Bundle.module.url(forResource:withExtension:)` and construct the session
with `SKTestSession(contentsOf:)` instead.

**Configuration.storekit is duplicated**, not shared, between
`Tests/PurchaseSupportTests/` and `Tests/AsyncSequenceCollectingTests/`:
SwiftPM resources must live inside the target that references them, so a
single file can't be pointed at from two test targets. If you need to
change the StoreKit test configuration, update both copies.

**Five tests are skipped in `swift-test`/`kit-tests-ios` (and their `make`
equivalents)** because they need a real Xcode-built host app bundle to work
at all — confirmed by each failing consistently, not intermittently, and one
hanging outright rather than failing:

| Test | Why | Real-path coverage lives in |
|---|---|---|
| `PurchaseSupportTests.testFetchAndPurchaseTipProduct` | Real StoreKit product lookup returns nil with no host app identity | `QuoteBoxUITests.testTipJarPurchaseResolvesAgainstWiredStoreKitConfiguration` |
| `PurchaseSupportTests.testIsEntitledReflectsRealPurchaseUnderTestSession` | Same | Same |
| `AsyncSequenceCollectingTests.testCollectsRealTransactionUpdateAfterExternalPurchase` | Same | Same |
| `ClipboardProvidingTests.testSystemProviderRoundTripsAgainstRealPasteboard` | Hung indefinitely — almost certainly iOS 16+'s paste-permission alert, which a headless process can never dismiss | `MockClipboardProvider` coverage only; real round trip now covered by `QuoteBoxUITests.testDebugTabShowsRealClipboardRoundTrip` instead — a same-process copy/read from inside QuoteBox's own bundle identity, surfaced on the Debug tab, doesn't hit the alert the way this bare-bundle attempt does |
| `IdleTimerControllingTests.testSystemControlRoundTripsAgainstRealApplication` | `UIApplication.shared.isIdleTimerDisabled` writes don't take effect without a real running host app | `MockIdleTimerControl` coverage only |

Mock-backed coverage for all five still runs everywhere. If you add a new
"real system, mutates real app/OS state" test, expect it to need the same
treatment until proven otherwise.

`LocalNotificationsTests` has no `SystemReminderScheduler` test at all, not
even for a nominally non-prompting call like `cancelDailyReminder()`:
`SystemReminderScheduler`'s default `center` argument eagerly evaluates
`UNUserNotificationCenter.current()`, which crashes with
`"bundleProxyForCurrentProcess is nil"` outside a real host app bundle -
confirmed by CI on both `swift test` and `xcodebuild test -scheme
iOSTestKit-Package`. `MockReminderScheduler` coverage only. Every `QuoteBoxUITests` run launches
with a `--mock-*` flag, so `SystemReminderScheduler` is never exercised by an
automated test at all today - only by a person running the real (non-mock)
app build by hand, where `QuoteBoxApp.swift`/`QuoteStore.swift`'s default
argument constructs it inside a real host app bundle. Closing that
automated-coverage gap for real would need the same `--real-*`-flag approach
`--real-purchases`/`--real-clipboard` already use.

## Pull requests

- Keep one module or fix per PR where practical — the module-per-PR history
  in `git log` is what the CHANGELOG entries are built from.
- Bump the version references (README's `.package(url:from:)` example,
  `CHANGELOG.md`) in a dedicated PR when cutting a release, rather than
  folding a version bump into a feature PR.
