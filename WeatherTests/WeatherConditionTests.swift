import XCTest
@testable import Weather

final class WeatherConditionTests: XCTestCase {
    func testKnownCodesMapToExpectedDescriptions() {
        XCTAssertEqual(WeatherCondition.description(for: 0), "Clear sky")
        XCTAssertEqual(WeatherCondition.description(for: 61), "Rain")
        XCTAssertEqual(WeatherCondition.description(for: 95), "Thunderstorm")
    }

    func testKnownCodesMapToExpectedSymbols() {
        XCTAssertEqual(WeatherCondition.symbolName(for: 0), "sun.max")
        XCTAssertEqual(WeatherCondition.symbolName(for: 61), "cloud.rain")
    }

    func testUnknownCodeFallsBackToUnknown() {
        XCTAssertEqual(WeatherCondition.description(for: -1), "Unknown")
        XCTAssertEqual(WeatherCondition.symbolName(for: -1), "questionmark")
    }
}
