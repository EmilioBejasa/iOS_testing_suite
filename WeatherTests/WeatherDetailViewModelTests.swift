import XCTest
@testable import Weather

@MainActor
final class WeatherDetailViewModelTests: XCTestCase {
    private let listItem = MockWeatherAPIClient.defaultListItems[0]

    func testLoadSuccessPopulatesState() async {
        let viewModel = WeatherDetailViewModel(listItem: listItem, apiClient: MockWeatherAPIClient(mode: .success))
        await viewModel.load()
        XCTAssertEqual(viewModel.state, .loaded(MockWeatherAPIClient.defaultDetail))
    }

    func testLoadFailurePopulatesErrorMessage() async {
        let viewModel = WeatherDetailViewModel(listItem: listItem, apiClient: MockWeatherAPIClient(mode: .failure(.decodingFailed)))
        await viewModel.load()
        XCTAssertEqual(viewModel.state, .error(APIError.decodingFailed.errorDescription!))
    }
}
