#if os(iOS)
import BackgroundTasks

/// Records what a call site asked the scheduler to do, rather than faking real
/// scheduling behavior - it can't invoke a registered launch handler with a
/// working fake `BGTask`, since (like StoreKit's `Product`) `BGTask` has no
/// public initializer. Still lets a test assert the right identifiers were
/// registered/submitted/cancelled, which is what most app-level bugs in this
/// area actually look like.
public final class MockBackgroundTaskScheduler: BackgroundTaskScheduling {
    public private(set) var registeredIdentifiers: [String] = []
    public private(set) var submittedRequests: [BGTaskRequest] = []
    public private(set) var cancelledIdentifiers: [String] = []
    public var registerResult = true
    public var submitError: Error?

    public init() {}

    @discardableResult
    public func register(forTaskWithIdentifier identifier: String, launchHandler: @escaping (BGTask) -> Void) -> Bool {
        registeredIdentifiers.append(identifier)
        return registerResult
    }

    public func submit(_ request: BGTaskRequest) throws {
        if let submitError {
            throw submitError
        }
        submittedRequests.append(request)
    }

    public func cancel(taskRequestWithIdentifier identifier: String) {
        cancelledIdentifiers.append(identifier)
    }
}
#endif
