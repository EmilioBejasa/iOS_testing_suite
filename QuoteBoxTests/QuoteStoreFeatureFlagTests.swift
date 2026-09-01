import XCTest
import AccessibilityStateProviding
import FeatureFlagging
import HapticFeedbackProviding
import UIKit
@testable import QuoteBox

/// Split out of `QuoteStoreTests.swift` to keep that file under SwiftLint's
/// `file_length` limit (400 lines) once analytics/haptics coverage was added
/// alongside it - groups every test that asserts on `FeatureFlagging`-gated
/// behavior, covering both flags `QuoteStore` resolves (`"newQuoteLayout"`,
/// `"hapticFeedbackEnabled"`).
@MainActor
final class QuoteStoreFeatureFlagTests: XCTestCase {
    func testUsesNewQuoteLayoutReflectsEnabledFlag() {
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            featureFlags: MockFeatureFlags(overrides: ["newQuoteLayout": true])
        )

        XCTAssertTrue(store.usesNewQuoteLayout)
    }

    func testUsesNewQuoteLayoutDefaultsFalseWhenFlagUnset() {
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            featureFlags: MockFeatureFlags()
        )

        XCTAssertFalse(store.usesNewQuoteLayout)
    }

    func testHapticFeedbackEnabledReflectsEnabledFlag() {
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            featureFlags: MockFeatureFlags(overrides: ["hapticFeedbackEnabled": true])
        )

        XCTAssertTrue(store.hapticFeedbackEnabled)
    }

    func testHapticFeedbackEnabledDefaultsFalseWhenFlagUnset() {
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(Quote(id: 1, quote: "Q", author: "A"))),
            favoritesStore: InMemoryFavoritesStore(),
            featureFlags: MockFeatureFlags()
        )

        XCTAssertFalse(store.hapticFeedbackEnabled)
    }

    func testToggleFavoriteFiresHapticFeedbackWhenFlagEnabled() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let haptics = MockHapticFeedbackProvider()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            featureFlags: MockFeatureFlags(overrides: ["hapticFeedbackEnabled": true]),
            haptics: haptics
        )
        await store.fetchNewQuote()

        await store.toggleFavoriteForCurrentQuote()

        XCTAssertEqual(haptics.impactStyles, [.light])
    }

    func testToggleFavoriteDoesNotFireHapticFeedbackWhenFlagDisabled() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let haptics = MockHapticFeedbackProvider()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            featureFlags: MockFeatureFlags(),
            haptics: haptics
        )
        await store.fetchNewQuote()

        await store.toggleFavoriteForCurrentQuote()

        XCTAssertTrue(haptics.impactStyles.isEmpty)
    }

    /// Custom haptics are suppressed while VoiceOver is running (see
    /// `QuoteStore.toggleFavoriteForCurrentQuote()`'s doc comment) even when
    /// `"hapticFeedbackEnabled"` is on - `AccessibilityStateProviding` gates
    /// the flag rather than replacing it, so both conditions are exercised
    /// independently here and in the flag-disabled test above.
    func testToggleFavoriteDoesNotFireHapticFeedbackWhenVoiceOverIsRunning() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let haptics = MockHapticFeedbackProvider()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            featureFlags: MockFeatureFlags(overrides: ["hapticFeedbackEnabled": true]),
            haptics: haptics,
            accessibilityState: MockAccessibilityStateProvider(voiceOverRunning: true)
        )
        await store.fetchNewQuote()

        await store.toggleFavoriteForCurrentQuote()

        XCTAssertTrue(haptics.impactStyles.isEmpty)
    }

    func testToggleFavoriteFiresHapticFeedbackWhenVoiceOverIsNotRunning() async {
        let quote = Quote(id: 1, quote: "Test quote", author: "Test Author")
        let haptics = MockHapticFeedbackProvider()
        let store = QuoteStore(
            apiClient: MockQuoteAPIClient(mode: .success(quote)),
            favoritesStore: InMemoryFavoritesStore(),
            featureFlags: MockFeatureFlags(overrides: ["hapticFeedbackEnabled": true]),
            haptics: haptics,
            accessibilityState: MockAccessibilityStateProvider(voiceOverRunning: false)
        )
        await store.fetchNewQuote()

        await store.toggleFavoriteForCurrentQuote()

        XCTAssertEqual(haptics.impactStyles, [.light])
    }
}
