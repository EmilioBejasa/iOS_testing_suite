import SwiftUI

struct FavoritesView: View {
    let store: QuoteStore

    var body: some View {
        NavigationStack {
            Group {
                if store.favorites.isEmpty {
                    Text("No favorites yet")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("favorites.empty")
                } else {
                    List(store.favorites) { quote in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(quote.quote)
                            Text("— \(quote.author)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityIdentifier("favoritesRow.\(quote.id)")
                    }
                    .accessibilityIdentifier("favorites.list")
                }
            }
            .navigationTitle("Favorites")
        }
    }
}
