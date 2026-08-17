import Foundation

/// Lets app code ask "how much disk space is available/does this device
/// have in total?" through an injectable dependency instead of reading
/// `URLResourceValues`' volume capacity keys directly, so a test can force a
/// low-space scenario (skip a cache prefetch, warn before a large download)
/// deterministically. Plain, synchronous Foundation reads, not UIKit, so no
/// `@MainActor` bridging is needed - same reasoning `PowerStateProviding`/
/// `BundleInfoProviding` give for their own Foundation-only touchpoints.
///
/// Returns `Int64?` (bytes) rather than a non-optional value or a
/// `Double`/`Measurement`: the underlying resource values can genuinely be
/// unavailable (a volume that doesn't report capacity), and bytes as a
/// plain integer avoids forcing every call site to pull in `Measurement`
/// just to read a count. `availableCapacity()` deliberately wraps
/// `volumeAvailableCapacityForImportantUsage` rather than the plainer
/// `volumeAvailableCapacity` - Apple's own guidance is that the
/// "important usage" key is the one to check before an operation the user
/// actually asked for (a download, an export), since it accounts for space
/// the system might reclaim from purgeable/opportunistic data if needed,
/// giving a more realistic answer than the raw free-space number.
public protocol DiskSpaceChecking {
    func availableCapacity() -> Int64?
    func totalCapacity() -> Int64?
}
