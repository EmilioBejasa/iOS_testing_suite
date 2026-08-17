/// Deterministic stand-in for `SystemDiskSpaceChecker` - safe to exercise in
/// any test, since it never touches the real filesystem/volume.
public final class MockDiskSpaceChecker: DiskSpaceChecking {
    public var available: Int64?
    public var total: Int64?

    public init(available: Int64? = 64_000_000_000, total: Int64? = 128_000_000_000) {
        self.available = available
        self.total = total
    }

    public func availableCapacity() -> Int64? {
        available
    }

    public func totalCapacity() -> Int64? {
        total
    }
}
