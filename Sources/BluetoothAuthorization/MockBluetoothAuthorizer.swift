import CoreBluetooth

/// Deterministic stand-in for `SystemBluetoothAuthorizer` - safe to exercise
/// in any test, since it never touches the real Bluetooth manager.
@available(iOS 13.1, *)
public final class MockBluetoothAuthorizer: BluetoothAuthorizing {
    public var status: CBManagerAuthorization

    public init(status: CBManagerAuthorization = .notDetermined) {
        self.status = status
    }

    public func currentAuthorizationStatus() -> CBManagerAuthorization {
        status
    }
}
