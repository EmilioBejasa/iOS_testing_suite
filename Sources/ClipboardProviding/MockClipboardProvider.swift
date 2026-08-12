/// Deterministic stand-in for `SystemClipboardProvider` - safe to exercise
/// in any test, since it never touches the real Simulator pasteboard.
public final class MockClipboardProvider: ClipboardProviding {
    public var storedString: String?

    public init(storedString: String? = nil) {
        self.storedString = storedString
    }

    public func copy(_ string: String) {
        storedString = string
    }

    public func currentString() -> String? {
        storedString
    }
}
