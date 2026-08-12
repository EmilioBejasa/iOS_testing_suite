/// Lets app code copy to/read from the system clipboard through an
/// injectable dependency instead of touching `UIPasteboard` directly, so a
/// test can assert "did my code copy the right string" without depending on
/// the real Simulator pasteboard's state persisting across runs.
public protocol ClipboardProviding {
    func copy(_ string: String)
    func currentString() -> String?
}
