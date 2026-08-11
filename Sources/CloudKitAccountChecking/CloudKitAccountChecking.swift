import CloudKit

/// Keeps `CKAccountStatus` directly rather than reinventing an enum, same
/// reasoning every permission/status module in this kit gives for keeping a
/// framework's own type.
public protocol CloudKitAccountChecking {
    func accountStatus() async -> CKAccountStatus
}
