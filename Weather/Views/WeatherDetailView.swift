import SwiftUI

struct WeatherDetailView: View {
    @StateObject private var viewModel: WeatherDetailViewModel

    init(viewModel: @autoclosure @escaping () -> WeatherDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        content
            .navigationTitle(title)
            .task {
                await viewModel.load()
            }
    }

    private var title: String {
        if case .loaded(let detail) = viewModel.state {
            return detail.city
        }
        return "Weather"
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading...")
                .accessibilityIdentifier("weatherDetail.loading")
        case .error(let message):
            VStack(spacing: 16) {
                Text(message)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("weatherDetail.errorMessage")
                Button("Retry") {
                    Task { await viewModel.load() }
                }
                .accessibilityIdentifier("weatherDetail.retryButton")
            }
            .padding()
        case .loaded(let detail):
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: WeatherCondition.symbolName(for: detail.weatherCode))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("weatherDetail.icon")

                    Text(detail.country)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(Int(detail.temperatureF.rounded()))°F")
                        .font(.system(size: 48, weight: .semibold))
                        .accessibilityIdentifier("weatherDetail.temperature")

                    Text(WeatherCondition.description(for: detail.weatherCode))
                        .font(.title3)
                        .accessibilityIdentifier("weatherDetail.condition")

                    HStack(spacing: 24) {
                        VStack {
                            Text("\(detail.humidityPercent)%").font(.headline)
                            Text("Humidity").font(.caption).foregroundStyle(.secondary)
                        }
                        VStack {
                            Text("\(Int(detail.windSpeedKmh.rounded())) km/h").font(.headline)
                            Text("Wind").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("weatherDetail.measurements")

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(detail.dailyForecasts) { day in
                            HStack {
                                Text(day.date)
                                Spacer()
                                Image(systemName: WeatherCondition.symbolName(for: day.weatherCode))
                                    .foregroundStyle(.secondary)
                                Text("\(Int(day.minTemperatureF.rounded()))° / \(Int(day.maxTemperatureF.rounded()))°")
                            }
                        }
                    }
                    .padding(.horizontal)
                    .accessibilityIdentifier("weatherDetail.dailyForecast")
                }
                .padding()
            }
        }
    }
}
