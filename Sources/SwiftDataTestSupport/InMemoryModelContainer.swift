import SwiftData

/// Builds a `ModelContainer` backed by an in-memory store instead of SQLite
/// on disk, so SwiftData-backed persistence can be unit-tested without
/// touching the filesystem or leaking state between tests - the SwiftData
/// counterpart to `CoreDataTestSupport`'s `InMemoryPersistentContainer`.
/// Takes a plain `[any PersistentModel.Type]` array rather than a variadic
/// parameter: `ModelContainer`'s own initializer is itself variadic, and
/// Swift doesn't let one variadic parameter forward into another without
/// first collecting it into a `Schema`, so this builds the `Schema` (which
/// does take an array) explicitly rather than passing types straight
/// through. `@available(iOS 17.0, *)` since SwiftData itself is - newer than
/// the package's iOS 13 floor (`Package.swift`), same class of annotation
/// `BluetoothAuthorization` needed for `CBManagerAuthorization`.
@available(iOS 17.0, *)
public enum InMemoryModelContainer {
    public static func make(for types: [any PersistentModel.Type]) -> ModelContainer {
        let schema = Schema(types)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            preconditionFailure("Failed to load in-memory SwiftData container: \(error)")
        }
    }
}
