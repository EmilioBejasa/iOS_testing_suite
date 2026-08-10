import CoreData

/// Builds an `NSPersistentContainer` backed by an in-memory store instead of SQLite
/// on disk, so Core Data-backed persistence can be unit-tested without touching the
/// filesystem or leaking state between tests. Works for any app's `.xcdatamodeld` —
/// just point it at the model name and the bundle it lives in.
public enum InMemoryPersistentContainer {
    public static func make(modelName: String, bundle: Bundle) -> NSPersistentContainer {
        guard let modelURL = bundle.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            preconditionFailure("Couldn't load Core Data model \"\(modelName)\" from \(bundle)")
        }

        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        precondition(loadError == nil, "Failed to load in-memory Core Data store: \(loadError!)")

        return container
    }
}
