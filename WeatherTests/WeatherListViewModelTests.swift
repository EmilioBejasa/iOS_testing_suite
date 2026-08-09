import XCTest
@testable import Weather

@MainActor
final class WeatherListViewModelTests: XCTestCase {
    func testFilteredItemsEmptyWhileLoading() {
        let viewModel = WeatherListViewModel(apiClient: MockWeatherAPIClient(mode: .success))
        XCTAssertEqual(viewModel.filteredItems, [])
    }

    func testLoadSuccessPopulatesState() async {
        let viewModel = WeatherListViewModel(apiClient: MockWeatherAPIClient(mode: .success))
        await viewModel.load()
        XCTAssertEqual(viewModel.state, .loaded(MockWeatherAPIClient.defaultListItems))
    }

    func testLoadEmptyPopulatesEmptyList() async {
        let viewModel = WeatherListViewModel(apiClient: MockWeatherAPIClient(mode: .empty))
        await viewModel.load()
        XCTAssertEqual(viewModel.state, .loaded([]))
    }

    func testLoadFailurePopulatesErrorMessage() async {
        let viewModel = WeatherListViewModel(apiClient: MockWeatherAPIClient(mode: .failure(.requestFailed)))
        await viewModel.load()
        XCTAssertEqual(viewModel.state, .error(APIError.requestFailed.errorDescription!))
    }

    func testFilteredItemsReturnsAllWhenSearchTextEmpty() async {
        let viewModel = WeatherListViewModel(apiClient: MockWeatherAPIClient(mode: .success))
        await viewModel.load()
        XCTAssertEqual(viewModel.filteredItems, MockWeatherAPIClient.defaultListItems)
    }

    func testFilteredItemsMatchesSearchTextCaseInsensitively() async {
        let viewModel = WeatherListViewModel(apiClient: MockWeatherAPIClient(mode: .success))
        await viewModel.load()
        viewModel.searchText = "lon"
        XCTAssertEqual(viewModel.filteredItems.map(\.city), ["London"])
    }

    func testFilteredItemsEmptyWhenNoCityMatches() async {
        let viewModel = WeatherListViewModel(apiClient: MockWeatherAPIClient(mode: .success))
        await viewModel.load()
        viewModel.searchText = "Atlantis"
        XCTAssertEqual(viewModel.filteredItems, [])
    }
}
