import SwiftUI
import WidgetKit

struct QuoteWidgetView: View {
    let entry: QuoteWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.quoteText)
                .font(.caption)
                .lineLimit(4)
            Text("— \(entry.author)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct QuoteBoxWidget: Widget {
    let kind = "QuoteBoxWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteWidgetProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("QuoteBox")
        .description("Shows the most recently viewed quote.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
