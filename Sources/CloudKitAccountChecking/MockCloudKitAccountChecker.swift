import CloudKit

/// Deterministic stand-in for `SystemCloudKitAccountChecker` - safe to exercise
/// in any test, since it never touches the real CloudKit framework.
public final class MockCloudKitAccountChecker: CloudKitAccountChecking {
    public var status: CKAccountStatus

    public init(status: CKAccountStatus = .available) {
        self.status = status
    }

    public func accountStatus() async -> CKAccountStatus {
        status
    }
}
