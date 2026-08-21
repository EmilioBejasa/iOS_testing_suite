import XCTest
import JSONFixtureLoading

private struct SampleFixture: Decodable, Equatable {
    let name: String
    let count: Int
}

final class JSONFixtureLoadingTests: XCTestCase {
    func testLoadsAndDecodesRealFixture() throws {
        let fixture = try JSONFixtureLoading.load(
            "sample-fixture",
            as: SampleFixture.self,
            bundle: .module
        )

        XCTAssertEqual(fixture, SampleFixture(name: "test-fixture", count: 3))
    }

    func testThrowsFixtureNotFoundForMissingResource() {
        XCTAssertThrowsError(
            try JSONFixtureLoading.load(
                "does-not-exist",
                as: SampleFixture.self,
                bundle: .module
            )
        ) { error in
            guard case FixtureLoadingError.fixtureNotFound(let name) = error else {
                return XCTFail("Expected .fixtureNotFound, got \(error)")
            }
            XCTAssertEqual(name, "does-not-exist")
        }
    }
}
