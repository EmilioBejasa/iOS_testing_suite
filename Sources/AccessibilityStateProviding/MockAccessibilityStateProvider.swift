/// Deterministic stand-in for `SystemAccessibilityStateProvider` - safe to
/// exercise in any test, since it never touches the real accessibility
/// settings. Stays `async` to match the protocol, even though nothing here
/// actually needs to suspend.
public final class MockAccessibilityStateProvider: AccessibilityStateProviding {
    public var voiceOverRunning: Bool
    public var reduceMotionEnabled: Bool

    public init(voiceOverRunning: Bool = false, reduceMotionEnabled: Bool = false) {
        self.voiceOverRunning = voiceOverRunning
        self.reduceMotionEnabled = reduceMotionEnabled
    }

    public func isVoiceOverRunning() async -> Bool {
        voiceOverRunning
    }

    public func isReduceMotionEnabled() async -> Bool {
        reduceMotionEnabled
    }
}
