import CoreBluetooth

/// A twelfth permission-gated system service, same structural outlier as
/// `MotionAuthorization`: Bluetooth authorization is requested implicitly
/// when a `CBCentralManager` is instantiated and used, not via a separate
/// explicit request call, so this protocol only has a status read.
///
/// `CBManagerAuthorization`/`CBManager.authorization` is `@available(iOS
/// 13.1, *)` in Apple's headers - newer than the package's iOS 13 floor
/// (`Package.swift`) - so merely naming the type here requires this
/// annotation, same class of fix `TrackingAuthorizing` needed for
/// `ATTrackingManager` and `AsyncSleeping` needed for `Duration`. Applied
/// here from the start rather than discovered via a failed CI run.
@available(iOS 13.1, *)
public protocol BluetoothAuthorizing {
    func currentAuthorizationStatus() -> CBManagerAuthorization
}
