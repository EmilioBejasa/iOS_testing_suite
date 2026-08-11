import SwiftUI
import XCTest

/// Renders `view` via `ImageRenderer` and compares it against a reference PNG
/// checked into the repo, stored alongside the calling test file under
/// `__Snapshots__/<TestFileName>/<testName>.<name>.png`. Rendered at a fixed
/// `size` and scale rather than the device's actual screen dimensions, so one
/// reference image stays valid across an entire CI device matrix instead of
/// needing a baseline per simulator.
///
/// Set the `SNAPSHOT_RECORD=1` environment variable to write a new reference
/// image instead of comparing — the test still fails when recording, so
/// recording mode can't be left on by accident.
@available(iOS 16.0, *)
@MainActor
public func assertSnapshot(
    of view: some View,
    size: CGSize = CGSize(width: 300, height: 300),
    named name: String,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line
) {
    let renderer = ImageRenderer(
        content: view.frame(width: size.width, height: size.height).environment(\.colorScheme, .light)
    )
    renderer.scale = 2

    guard let renderedData = renderer.uiImage?.pngData() else {
        XCTFail("Failed to render \"\(name)\" to an image", file: file, line: line)
        return
    }

    let snapshotURL = snapshotFileURL(for: file, testName: testName, named: name)

    if ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1" {
        try? FileManager.default.createDirectory(at: snapshotURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? renderedData.write(to: snapshotURL)
        XCTFail(
            "Recorded a new snapshot at \(snapshotURL.path) - rerun without SNAPSHOT_RECORD=1 to verify against it",
            file: file,
            line: line
        )
        return
    }

    guard let referenceData = try? Data(contentsOf: snapshotURL) else {
        XCTFail("No reference snapshot at \(snapshotURL.path) - run with SNAPSHOT_RECORD=1 to record one", file: file, line: line)
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
