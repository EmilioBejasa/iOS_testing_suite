import SwiftUI

struct WeatherListView: View {
    @StateObject private var viewModel: WeatherListViewModel
    private let apiClient: WeatherAPIClientProtocol

    init(apiClient: WeatherAPIClientProtocol) {
        self.apiClient = apiClient
        _viewModel = StateObject(wrappedValue: WeatherListViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Weather")
                .searchable(text: $viewModel.searchText, prompt: "Search cities")
                .task {
                    await viewModel.load()
                }
                .navigationDestination(for: WeatherListItem.self) { item in
                    WeatherDetailView(
                        viewModel: WeatherDetailViewModel(listItem: item, apiClient: apiClient)
                    )
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading...")
                .accessibilityIdentifier("weatherList.loading")
        case .error(let message):
            errorView(message)
        case .loaded:
            if viewModel.filteredItems.isEmpty {
                Text("No cities found")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("weatherList.noResults")
            } else {
                List(viewModel.filteredItems) { item in
                    NavigationLink(value: item) {
                        WeatherRowView(item: item)
                    }
                }
                .accessibilityIdentifier("weatherList.list")
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("weatherList.errorMessage")
            Button("Retry") {
                Task { await viewModel.load() }
            }
            .accessibilityIdentifier("weatherList.retryButton")
        }
        .padding()
    }
}
