import XCTest
import DeepLinkTesting
@testable import QuoteBox

final class QuoteBoxRouteTests: XCTestCase {
    func testFavoritesURLParsesToFavoritesRoute() {
        let url = URL(string: "quotebox://favorites")!

        XCTAssertEqual(QuoteBoxRoute(url: url), .favorites)
    }

    func testUnknownHostFailsToParse() {
        let url = URL(string: "quotebox://somewhere-else")!

        XCTAssertNil(QuoteBoxRoute(url: url))
    }

    func testWrongSchemeFailsToParse() {
        let url = URL(string: "https://favorites")!

        XCTAssertNil(QuoteBoxRoute(url: url))
    }

    func testDeepLinkSourceParsesLaunchArgument() {
        let arguments = ["QuoteBox", "--mock-success", "--deep-link", "quotebox://favorites"]

        XCTAssertEqual(DeepLinkSource.url(from: arguments), URL(string: "quotebox://favorites"))
    }

    func testDeepLinkSourceReturnsNilWithoutTheArgument() {
        let arguments = ["QuoteBox", "--mock-success"]

        XCTAssertNil(DeepLinkSource.url(from: arguments))
    }

    func testUniversalLinkSourceParsesLaunchArgument() {
        let arguments = ["QuoteBox", "--mock-success", "--universal-link", "https://quotebox.qa/favorites"]

        XCTAssertEqual(UniversalLinkSource.url(from: arguments), URL(string: "https://quotebox.qa/favorites"))
    }

    func testUniversalLinkSourceReturnsNilWithoutTheArgument() {
        let arguments = ["QuoteBox", "--mock-success"]

        XCTAssertNil(UniversalLinkSource.url(from: arguments))
    }
}
