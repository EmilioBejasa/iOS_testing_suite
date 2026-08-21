import EventKit

/// Wraps `EKEventStore`. Unlike `SystemContactsAuthorizer`, no completion-handler
/// bridging is needed here: `requestFullAccessToEvents()` (iOS 17+) is already a
/// native `async throws` API, the same "already async" story
/// `SystemPhotoLibraryAuthorizer` gives for `PHPhotoLibrary`. Deliberately
/// targets the iOS 17 API rather than the older, deprecated
/// `requestAccess(to:completion:)` - QuoteBox's own deployment target is
/// already 17.0 (`project.yml`'s `IPHONEOS_DEPLOYMENT_TARGET`), so there's no
/// floor this module needs to stay under the way `MicrophoneAuthorization`
/// does for `AVAudioApplication`.
@available(iOS 17.0, macOS 14.0, *)
public final class SystemCalendarAuthorizer: CalendarAuthorizing {
    private let store = EKEventStore()

    public init() {}

    public func currentAuthorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    public func requestAccess() async -> Bool {
        (try? await store.requestFullAccessToEvents()) ?? false
    }
}
