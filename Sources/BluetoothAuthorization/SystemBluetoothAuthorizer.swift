import CoreBluetooth

/// Wraps `CBManager.authorization` - a static, synchronous, non-prompting
/// read. Reading it doesn't trigger the permission prompt; only actually
/// starting/using a `CBCentralManager` does.
@available(iOS 13.1, *)
public final class SystemBluetoothAuthorizer: BluetoothAuthorizing {
    public init() {}

    public func currentAuthorizationStatus() -> CBManagerAuthorization {
        CBManager.authorization
    }
}
