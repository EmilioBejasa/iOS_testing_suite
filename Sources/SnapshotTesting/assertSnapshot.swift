#if os(iOS)
import SwiftUI
import XCTest

/// Renders `view` via `ImageRenderer` and compares it against a reference PNG
/// checked into the repo, stored alongside the calling test file under
/// `__Snapshots__/<TestFileName>/<testName>.<name>.png`. Rendered at a fixed
/// `size` and scale rather than the device's actual screen dimensions, so one
/// reference image stays valid across an entire CI device matrix instead of
/// needing a baseline per simulator.
///
/// `locale` and `dynamicTypeSize` default to `nil`, leaving every existing call
/// site unaffected - pass one to snapshot the same view under a specific locale
/// or text size instead of relying on an accessibility audit's allow-listed
/// exception to paper over not actually rendering it. The caller picks a
/// distinct `name` per variant (e.g. `"loaded-accessibility3"`); there's no
/// automatic filename suffixing, matching how `name` already works today.
///
/// Set the `SNAPSHOT_RECORD=1` environment variable to write a new reference
/// image instead of comparing — the test still fails when recording, so
/// recording mode can't be left on by accident.
///
/// A Simulator-hosted test process only sees environment variables its
/// scheme explicitly maps in (not the invoking shell's environment) — pass
/// `SNAPSHOT_RECORD=1` as a bare `xcodebuild` build-setting override (e.g.
/// `xcodebuild test ... SNAPSHOT_RECORD=1`, the same style as
/// `CODE_SIGNING_ALLOWED=NO`), which reaches this via the `test` scheme's
/// `SNAPSHOT_RECORD: $(SNAPSHOT_RECORD)` environment-variable mapping in
/// `project.yml`. A plain shell `export SNAPSHOT_RECORD=1` before the
/// `xcodebuild` invocation does not reach this check.
@available(iOS 16.0, *)
@MainActor
public func assertSnapshot(
    of view: some View,
    size: CGSize = CGSize(width: 300, height: 300),
    locale: Locale? = nil,
    dynamicTypeSize: DynamicTypeSize? = nil,
    named name: String,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line
) {
    var content = AnyView(view.environment(\.colorScheme, .light))
    if let locale {
        content = AnyView(content.environment(\.locale, locale))
    }
    if let dynamicTypeSize {
        content = AnyView(content.dynamicTypeSize(dynamicTypeSize))
    }

    let renderer = ImageRenderer(content: content.frame(width: size.width, height: size.height))
    renderer.scale = 2

    // `List`/`ScrollView`/`NavigationStack`/`TabView` are UIKit-backed under the
    // hood and don't finish laying out their children on the very first
    // synchronous `.uiImage` read - discovered when FavoritesView/QuoteView/
    // RootView snapshots came back blank or, for the List case, indistinguishable
    // between an empty and a seeded list. A plain declarative leaf view (like
    // QuoteContentView) is already fully laid out on the first read, so this
    // warm-up read plus a short run-loop pass is a no-op for it, not a behavior
    // change - readers relying on that existing golden coverage aren't affected.
    _ = renderer.uiImage
    RunLoop.main.run(until: Date().addingTimeInterval(0.1))

    guard let renderedData = renderer.uiImage?.pngData() else {
        XCTFail("Failed to render \"\(name)\" to an image", file: file, line: line)
        return
    }

    let snapshotURL = snapshotFileURL(for: file, testName: testName, named: name)

    if ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1" {
        try? FileManager.default.createDirectory(
            at: snapshotURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? renderedData.write(to: snapshotURL)
        XCTFail(
            "Recorded a new snapshot at \(snapshotURL.path) - rerun without SNAPSHOT_RECORD=1 to verify against it",
            file: file,
            line: line
        )
        return
    }

    guard let referenceData = try? Data(contentsOf: snapshotURL) else {
        XCTFail(
            "No reference snapshot at \(snapshotURL.path) - run with SNAPSHOT_RECORD=1 to record one",
            file: file,
            line: line
        )
        return
    }

    XCTAssertEqual(
        renderedData,
        referenceData,
        "Snapshot \"\(name)\" doesn't match the reference image at \(snapshotURL.path)",
        file: file,
        line: line
    )
}

private func snapshotFileURL(for file: StaticString, testName: String, named name: String) -> URL {
    let testFileURL = URL(fileURLWithPath: "\(file)")
    let testFileName = testFileURL.deletingPathExtension().lastPathComponent
    return testFileURL
        .deletingLastPathComponent()
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(testFileName)
        .appendingPathComponent("\(testName).\(name).png")
}
#endif
