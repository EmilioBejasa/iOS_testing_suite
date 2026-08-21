#if os(iOS)
import HomeKit

/// No explicit request API - HomeKit prompts implicitly on first real use,
/// same structural shape as `MotionAuthorizing`/`BluetoothAuthorizing`.
///
/// `HMHomeManagerAuthorizationStatus` is this kit's first `OptionSet`
/// status type - every other module keeps a plain enum. "Not determined" is
/// the **empty set `[]`**, not a named case (confirmed against the actual
/// header before writing this: `NS_OPTIONS` with three members -
/// `.determined`, `.restricted`, `.authorized` - no `.notDetermined`).
/// Available since iOS 13.0, matching the package's exact floor, so no
/// `@available` annotation is needed here.
public protocol HomeKitAuthorizing {
    func currentAuthorizationStatus() -> HMHomeManagerAuthorizationStatus
}
#endif
