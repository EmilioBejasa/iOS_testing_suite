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
}
