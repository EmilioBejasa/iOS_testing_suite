/// Fire-and-forget by design, matching `AppStore.requestReview(in:)` itself:
/// no return value, and no way for any app - including the real one - to know
/// whether the system actually presented the prompt, since iOS rate-limits and
/// decides that on its own.
public protocol ReviewRequesting {
    func requestReview()
}
