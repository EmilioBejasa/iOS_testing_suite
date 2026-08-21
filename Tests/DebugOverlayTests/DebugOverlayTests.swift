import XCTest
import DebugOverlay

/// `DebugOverlayView` itself is a thin SwiftUI list with nothing to unit test beyond what
/// snapshot testing already covers elsewhere (see `QuoteViewSnapshotTests`) — this exercises
/// `DebugSection.launchArguments(_:)` instead, the one piece of real parsing logic in this
/// module, previously untested (`DebugOverlay` had no dedicated test target at all).
final class DebugOverlayTests: XCTestCase {
    func testPairsEachFlagWithItsFollowingValue() {
        let section = DebugSection.launchArguments(["--deep-link", "quotebox://favorites", "--mock-success"])

        XCTAssertEqual(section.title, "Launch Arguments")
        XCTAssertEqual(section.rows.map(\.label), ["--deep-link", "--mock-success"])
        XCTAssertEqual(section.rows.map(\.value), ["quotebox://favorites", "—"])
    }

    func testFlagFollowedByAnotherFlagGetsAPlaceholderValue() {
        let section = DebugSection.launchArguments(["--mock-error", "--mock-success"])

        XCTAssertEqual(section.rows.map(\.label), ["--mock-error", "--mock-success"])
        XCTAssertEqual(section.rows.map(\.value), ["—", "—"])
    }

    func testFlagAtTheEndOfArgumentsGetsAPlaceholderValue() {
        let section = DebugSection.launchArguments(["--launch-count", "3", "--real-purchases"])

        XCTAssertEqual(section.rows.map(\.label), ["--launch-count", "--real-purchases"])
        XCTAssertEqual(section.rows.map(\.value), ["3", "—"])
    }

    func testIgnoresPlainArgumentsNotPrefixedWithDashDash() {
        let section = DebugSection.launchArguments(["/path/to/binary", "--mock-success"])

        XCTAssertEqual(section.rows.map(\.label), ["--mock-success"])
    }

    func testEmptyArgumentsProduceANoneRow() {
        let section = DebugSection.launchArguments([])

        XCTAssertEqual(section.rows.map(\.label), ["(none)"])
        XCTAssertEqual(section.rows.map(\.value), ["—"])
    }
}
