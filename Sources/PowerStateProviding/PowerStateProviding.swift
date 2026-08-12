/// Lets app code ask "is Low Power Mode on?" through an injectable dependency
/// instead of calling `ProcessInfo.processInfo.isLowPowerModeEnabled`
/// directly, so a test can force either side of a power-aware code path
/// (reduced polling, disabled animations) deterministically.
public protocol PowerStateProviding {
    var isLowPowerModeEnabled: Bool { get }
}
