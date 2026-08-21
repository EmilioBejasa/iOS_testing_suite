#if os(iOS)
import BackgroundTasks

public protocol BackgroundTaskScheduling {
    @discardableResult
    func register(forTaskWithIdentifier identifier: String, launchHandler: @escaping (BGTask) -> Void) -> Bool
    func submit(_ request: BGTaskRequest) throws
    func cancel(taskRequestWithIdentifier identifier: String)
}
#endif
