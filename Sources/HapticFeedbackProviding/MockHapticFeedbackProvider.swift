import UIKit

/// Deterministic stand-in for `SystemHapticFeedbackProvider` - records every
/// requested style rather than firing real haptics, so a test can assert
/// "did my code trigger the right feedback."
public final class MockHapticFeedbackProvider: HapticFeedbackProviding {
    public private(set) var impactStyles: [UIImpactFeedbackGenerator.FeedbackStyle] = []

    public init() {}

    public func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) async {
        impactStyles.append(style)
    }
}
