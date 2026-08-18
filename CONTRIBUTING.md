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
3. Add a test target under `QuoteBoxTests/<ModuleName>Tests.swift` that
   exercises it through QuoteBox (or documents why it's kit-level only, the
   way `LocalizationCompletenessChecking` does).
4. Add a `### \`ModuleName\`` section to the README, in the themed group it
   belongs to in the table of contents — body order should match TOC order.
   Mirror the module's doc comment closely; this kit keeps source doc
   comments and README prose in sync rather than treating them as separate
   writeups.
5. If the module has a deliberate limitation, call it out explicitly with a
   **Scope note**, the way `SnapshotTesting` and `LocalizationCompletenessChecking`
   do — this kit prefers documenting a gap honestly over silently under-covering it.

## Running tests locally

Requires Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) on
macOS:

```sh
xcodegen generate
xcodebuild test \
  -project QuoteBox.xcodeproj \
  -scheme QuoteBox \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -skip-testing:QuoteBoxTests/DummyJSONLiveContractTests
```

The live contract test hits a real network API and is excluded above; it
runs on a schedule via `.github/workflows/live-api-contract.yml` instead.
CI (`.github/workflows/ci.yml`) runs the same suite across a small device
matrix on every push and PR to `master`.

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
