import BackgroundTasks

/// Wraps `BGTaskScheduler.shared` directly - no bridging needed, but no safety
/// net either. `register`/`submit` have real, version-spanning crash reports tied
/// to registration timing (must happen before the app finishes launching) and to
/// identifiers missing from `Info.plist`'s `BGTaskSchedulerPermittedIdentifiers`.
/// Deliberately never exercised in this kit's own tests, even for a value that
/// looks safe - see `BackgroundTaskSchedulingTests.swift`.
public final class SystemBackgroundTaskScheduler: BackgroundTaskScheduling {
    public init() {}

    @discardableResult
    public func register(forTaskWithIdentifier identifier: String, launchHandler: @escaping (BGTask) -> Void) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil, launchHandler: launchHandler)
    }

    public func submit(_ request: BGTaskRequest) throws {
        try BGTaskScheduler.shared.submit(request)
    }

    public func cancel(taskRequestWithIdentifier identifier: String) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
    }
}
