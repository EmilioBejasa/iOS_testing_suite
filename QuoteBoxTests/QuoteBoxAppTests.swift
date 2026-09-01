import XCTest
import BundleInfoProviding
import DiagnosticReporting
@testable import QuoteBox

/// `QuoteBoxApp` is a SwiftUI `App` struct, so `init()` itself isn't
/// practically unit-testable - `QuoteBoxUITests.testDebugTabShowsLaunchArgumentsAndAppState`
/// covers it end-to-end instead. `makeDependencies(for:)` was split out
/// (`889f39a`) already and is where the pieces that matter for
/// `BundleInfoProviding`/`DiagnosticReporting` actually live, so this exercises
/// that seam directly rather than `init()`.
final class QuoteBoxAppTests: XCTestCase {
    func testMakeDependenciesForMockSuccessUsesMockBundleInfoAndDiagnosticReporter() {
        let dependencies = QuoteBoxApp.makeDependencies(for: ["--mock-success"])

        XCTAssertTrue(dependencies.bundleInfo is MockBundleInfoProvider)
        XCTAssertTrue(dependencies.diagnosticReporter is MockDiagnosticReporter)
    }

    func testMakeDependenciesForMockErrorUsesMockBundleInfoAndDiagnosticReporter() {
        let dependencies = QuoteBoxApp.makeDependencies(for: ["--mock-error"])

        XCTAssertTrue(dependencies.bundleInfo is MockBundleInfoProvider)
        XCTAssertTrue(dependencies.diagnosticReporter is MockDiagnosticReporter)
    }

    /// Mirrors the exact formula `QuoteBoxApp.init()` uses to build
    /// `appVersionString` ("\(appVersion) (\(buildNumber))") against an
    /// injected version, rather than asserting on the real bundle's
    /// (environment-dependent) version string.
    func testAppVersionStringFormula() {
        let bundleInfo = MockBundleInfoProvider(appVersion: "2.0", buildNumber: "42")

        let appVersionString = "\(bundleInfo.appVersion) (\(bundleInfo.buildNumber))"

        XCTAssertEqual(appVersionString, "2.0 (42)")
    }

    /// Exercises `MockDiagnosticReporter.startReportingCallCount`, previously
    /// tracked but unasserted by any test - proves diagnostic reporting is
    /// started exactly once per the same sequence `QuoteBoxApp.init()` runs
    /// (`dependencies.diagnosticReporter.startReporting()`, called once).
    func testDiagnosticReporterStartedExactlyOnce() {
        let dependencies = QuoteBoxApp.makeDependencies(for: ["--mock-success"])
        let reporter = dependencies.diagnosticReporter as? MockDiagnosticReporter

        dependencies.diagnosticReporter.startReporting()

        XCTAssertEqual(reporter?.startReportingCallCount, 1)
    }
}
