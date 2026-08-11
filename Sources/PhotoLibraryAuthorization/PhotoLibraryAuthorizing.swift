import Photos

/// A third permission-gated system service, following `LocalNotifications`'s and
/// `LocationAuthorization`'s protocol+real+fake shape. Uses `PHAuthorizationStatus`
/// directly (Photos' own richer type — `notDetermined`/`restricted`/`denied`/
/// `authorized`/`limited`) rather than reinventing a simplified enum that would
/// lose the `.limited` (partial photo access) case.
public protocol PhotoLibraryAuthorizing {
    func currentAuthorizationStatus() -> PHAuthorizationStatus
    func requestAuthorization() async -> PHAuthorizationStatus
}
