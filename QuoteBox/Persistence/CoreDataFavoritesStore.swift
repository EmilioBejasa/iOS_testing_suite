import CoreData

/// Persists favorites via Core Data (`FavoriteQuoteEntity` in `QuoteBox.xcdatamodeld`),
/// backed by whichever `NSPersistentContainer` it's given — a real on-disk one in
/// the running app, an in-memory one (via the kit's `CoreDataTestSupport` module)
/// in tests.
final class CoreDataFavoritesStore: FavoritesStoring {
    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer) {
        self.context = container.viewContext
    }

    func loadFavorites() -> [Quote] {
        let request = FavoriteQuoteEntity.fetchRequest()
        let entities = (try? context.fetch(request)) ?? []
        return entities.map { Quote(id: Int($0.id), quote: $0.quoteText ?? "", author: $0.author ?? "") }
    }

    func save(_ favorites: [Quote]) {
        let request = FavoriteQuoteEntity.fetchRequest()
        if let existing = try? context.fetch(request) {
            existing.forEach(context.delete)
        }
        for quote in favorites {
            let entity = FavoriteQuoteEntity(context: context)
            entity.id = Int64(quote.id)
            entity.quoteText = quote.quote
            entity.author = quote.author
        }
        try? context.save()
    }
}
