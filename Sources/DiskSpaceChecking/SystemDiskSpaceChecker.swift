import Foundation

/// Wraps `URL.resourceValues(forKeys:)` against the app's home directory -
/// the same volume every app-visible directory (Documents, Caches,
/// Application Support) lives on in the iOS sandbox, so there's no need to
/// pick a more specific directory. Both reads are `try?`-collapsed to `nil`
/// on failure rather than throwing - a disk space check failing shouldn't
/// itself be a reason to crash or propagate an error, the same
/// fail-soft reasoning `BundleInfoProviding` gives for defaulting to
/// `"unknown"` instead of crashing on a missing Info.plist key.
public final class SystemDiskSpaceChecker: DiskSpaceChecking {
    private let homeDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())

    public init() {}

    public func availableCapacity() -> Int64? {
        try? homeDirectoryURL
            .resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            .volumeAvailableCapacityForImportantUsage
    }

    public func totalCapacity() -> Int64? {
        let capacity: Int? = try? homeDirectoryURL
            .resourceValues(forKeys: [.volumeTotalCapacityKey])
            .volumeTotalCapacity
        return capacity.map(Int64.init)
    }
}
