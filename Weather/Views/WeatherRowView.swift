import SwiftUI

struct WeatherRowView: View {
    let item: WeatherListItem

    var body: some View {
        HStack {
            Image(systemName: WeatherCondition.symbolName(for: item.weatherCode))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(item.city)
                    .font(.body)
                Text(item.country)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(Int(item.temperatureF.rounded()))°F")
                .font(.headline)
        }
        .accessibilityIdentifier("weatherRow.\(item.city)")
    }
}
