import Foundation
import SwiftUI

public struct DebugRow: Identifiable {
    public let id = UUID()
    public let label: String
    public let value: String

    public init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }
}

public struct DebugSection: Identifiable {
    public let id = UUID()
    public let title: String
    public let rows: [DebugRow]

    public init(_ title: String, rows: [DebugRow]) {
        self.title = title
        self.rows = rows
    }
}

public extension DebugSection {
    /// Pairs each `--flag` in `arguments` with the plain value that follows it
    /// (e.g. `--deep-link quotebox://favorites`), the same shape every kit-backed
    /// dependency in this repo already switches behavior on
    /// (`--mock-success`/`--mock-error`/`--real-purchases`/`--deep-link ...`) — so a
    /// developer can see which mock path a build is running without re-reading the
    /// scheme or launch config.
    static func launchArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> DebugSection {
        var rows: [DebugRow] = []
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            if argument.hasPrefix("--") {
                var value = "—"
                if index + 1 < arguments.count, !arguments[index + 1].hasPrefix("--") {
                    value = arguments[index + 1]
                    index += 1
                }
                rows.append(DebugRow(argument, value))
            }
            index += 1
        }
        return DebugSection("Launch Arguments", rows: rows.isEmpty ? [DebugRow("(none)", "—")] : rows)
    }
}

/// A drop-in panel that surfaces runtime state a developer would otherwise need a
/// debugger attached to see — launch arguments, and whatever app-specific sections
/// the host app builds from its own stores (state machine values, mock flags,
/// counts). Generic on purpose: this module only renders `[DebugSection]`, so it
/// carries no dependency on any other module in this kit, the same way
/// `UITestHelpers` stays generic and lets the consuming app decide what's worth
/// showing.
///
/// `Package.swift` keeps this package's floor at iOS 13 so the rest of the kit
/// stays broadly compatible, but this view's body relies on APIs newer than
/// that (`Section(_:content:)` is iOS 15+, this `foregroundStyle` overload is
/// iOS 17+) — so it opts in per-symbol here, the same way
/// `SystemLocationAuthorizer` marks itself `@available(iOS 14.0, *)` rather than
/// raising the whole package's minimum.
@available(iOS 17.0, *)
public struct DebugOverlayView: View {
    private let sections: [DebugSection]

    public init(sections: [DebugSection]) {
        self.sections = sections
    }

    public var body: some View {
        List {
            ForEach(sections) { section in
                Section(section.title) {
                    ForEach(section.rows) { row in
                        HStack {
                            Text(row.label)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(row.value)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("debugOverlay.list")
    }
}
