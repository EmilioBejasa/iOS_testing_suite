import CloudKit

/// Wraps `CKContainer.default().accountStatus()` (native async throwing API,
/// iOS 15+), collapsing any thrown error to `.couldNotDetermine`. Deliberately
/// never called in this kit's own tests, even though it looks like a safe read
/// - without the `com.apple.developer.icloud-services` entitlement configured
/// (which `QuoteBox` doesn't have, same "no natural need" reasoning as
/// `LocationAuthorization`), this can crash with an uncatchable `CKException`
/// rather than throwing a normal Swift error. See
/// `CloudKitAccountCheckingTests.swift`.
@available(iOS 15.0, *)
public final class SystemCloudKitAccountChecker: CloudKitAccountChecking {
    public init() {}

    public func accountStatus() async -> CKAccountStatus {
        (try? await CKContainer.default().accountStatus()) ?? .couldNotDetermine
    }
}
