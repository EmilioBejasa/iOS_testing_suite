#if os(iOS)
import SwiftUI
import XCTest

/// Renders `view` (hosted in a real, offscreen `UIWindow` - see
/// `renderToPNGData` below for why) and compares it against a reference PNG
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
    // QuoteBox is iPhone-only (project.yml's TARGETED_DEVICE_FAMILY: "1"), so
    // the real app always runs in iOS's iPhone-compatibility mode even on an
    // iPad simulator - compact horizontal size class throughout. A raw
    // UIWindow (below) doesn't inherit that compatibility-mode emulation the
    // way a real launched app process does, so on an iPad runner it renders
    // NavigationStack/List content in native regular-width layout instead,
    // producing different bytes than the same test on iPhone (confirmed by
    // CI). Pinning compact here makes the snapshot match what every device
    // actually ships, not just what happens to be the CI runner's default.
    content = AnyView(content.environment(\.horizontalSizeClass, .compact))
    // Always pin explicitly, even in the nil (default) case - hosting in a
    // real UIWindow (below) means the render otherwise inherits whatever
    // Dynamic Type default the simulator/device happens to have, which
    // isn't guaranteed identical across the CI device matrix. Confirmed by
    // CI: the exact same view produced different byte counts on iPhone SE
    // vs. iPhone 16 with this left ambient - the whole point of a fixed
    // `size`/`scale` is one reference staying valid across every simulator,
    // and that's only true if every other rendering input is pinned too.
    content = AnyView(content.dynamicTypeSize(dynamicTypeSize ?? .large))

    guard let renderedData = renderToPNGData(content, size: size) else {
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

/// `ImageRenderer`'s synchronous capture (the original implementation here)
/// works for a plain declarative view tree like `QuoteContentView`, but
/// doesn't wait for `List`/`ScrollView`/`NavigationStack`/`TabView` - all
/// UIKit-backed under the hood - to finish laying out their children:
/// captures came back either fully blank (a bare `ScrollView`) or, for a
/// `List`, indistinguishable between meaningfully different states. Hosting
/// the view in a real, key `UIWindow` and forcing a layout pass before
/// rasterizing via `drawHierarchy` (rather than `ImageRenderer.uiImage`)
/// gives those UIKit-backed containers the live-window context they need to
/// actually lay out - a `RunLoop` delay alone, tried first, had zero effect,
/// confirmed byte-identical with or without it.
@available(iOS 16.0, *)
@MainActor
private func renderToPNGData(_ content: AnyView, size: CGSize) -> Data? {
    let hostingController = UIHostingController(rootView: content.frame(width: size.width, height: size.height))
    hostingController.view.frame = CGRect(origin: .zero, size: size)
    hostingController.view.backgroundColor = .white

    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    window.rootViewController = hostingController
    window.isHidden = false
    window.makeKeyAndVisible()
    hostingController.view.setNeedsLayout()
    hostingController.view.layoutIfNeeded()

    let format = UIGraphicsImageRendererFormat()
    format.scale = 2
    format.opaque = true
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let image = renderer.image { _ in
        hostingController.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
    }

    // Tear down so this window/controller doesn't linger across tests.
    window.rootViewController = nil
    window.isHidden = true

    return image.pngData()
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
