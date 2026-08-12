/// Wraps `Task.sleep(for:)` (iOS 16+, `Duration`-based clock API) directly -
/// no bridging needed, it's already the real `async throws` primitive every
/// other module's `System*` type is built on top of.
@available(iOS 16.0, *)
public struct SystemSleeper: AsyncSleeping {
    public init() {}

    public func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}
