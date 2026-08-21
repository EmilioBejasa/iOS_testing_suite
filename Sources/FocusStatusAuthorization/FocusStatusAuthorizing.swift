#if os(iOS)
import Intents

/// Same protocol+real+fake shape as `SiriAuthorization`. Uses
/// `INFocusStatusAuthorizationStatus` directly, same reasoning every other
/// module here gives for keeping a framework's own status type.
/// `INFocusStatusCenter`/`INFocusStatusAuthorizationStatus` is
/// `@available(iOS 15.0, *)` (confirmed via WebSearch before writing this),
/// annotated on the protocol, mock, AND system class from the start.
@available(iOS 15.0, *)
public protocol FocusStatusAuthorizing {
    func currentAuthorizationStatus() -> INFocusStatusAuthorizationStatus
    func requestAuthorization() async -> INFocusStatusAuthorizationStatus
}
#endif
