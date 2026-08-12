/// Lets app code ask "is this flag on?" through an injectable dependency
/// instead of branching on a hardcoded constant, so a test can force either
/// side of a flag-gated code path deterministically. Deliberately scoped to
/// a local override/QA-toggle mechanism, not a remote-config client: unlike
/// every other module in this kit, there's no single vendor-neutral Apple
/// framework for server-fetched flags to wrap, the same kind of honest scope
/// note `SnapshotTesting`'s README section gives for what it doesn't cover.
public protocol FeatureFlagging {
    func isEnabled(_ flag: String) -> Bool
}
