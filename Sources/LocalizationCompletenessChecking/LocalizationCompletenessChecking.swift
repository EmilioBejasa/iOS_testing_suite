import Foundation

/// One (key, locale) pair a String Catalog has no translated content for.
public struct MissingLocalization: Equatable {
    public let key: String
    public let locale: String

    public init(key: String, locale: String) {
        self.key = key
        self.locale = locale
    }
}

public enum LocalizationCatalogError: Error {
    case invalidCatalog
}

/// A single-file utility, same shape as `JSONFixtureLoading`/`SnapshotTesting`
/// - nothing to fake, no system framework to wrap, just a pure deterministic
/// function operating on a `.xcstrings` String Catalog the calling project
/// already has.
///
/// Complements `SnapshotTesting`'s `locale:` parameter rather than
/// overlapping it: that renders a view under a specific `Locale` and
/// compares pixels, but can only catch a bug if a translation *already
/// exists and got loaded*. This checks one layer earlier - whether a
/// translation was ever written at all - catching "nobody ever translated
/// this key" before a snapshot test would ever surface it visually.
///
/// **Scope note**, matching this kit's existing honesty pattern
/// (`SnapshotTesting`'s scope note, `FeatureFlagging`'s "not a
/// remote-config client" note): this checks that a locale has *some*
/// translated content for a key (a `stringUnit` with `state: "translated"`,
/// or a `variations` block present at all for plural/device-variant
/// strings) - it does not recursively validate that every plural category
/// within a `variations` block is individually translated. Modeling that
/// fully would mean hand-rolling a schema for Apple's plural-category/
/// device-variant shape (which has changed across Xcode versions) for a
/// level of precision this kit doesn't need; catching "this locale was
/// never touched" covers the common real bug.
public enum LocalizationCompletenessChecking {
    /// Reads the String Catalog JSON at `url` and reports every key that
    /// has no translated content for one of `locales`. Deliberately parses
    /// with `JSONSerialization` into loose `[String: Any]` dictionaries
    /// rather than strict `Decodable` structs, since the `variations` shape
    /// isn't being modeled per the scope note above - a loose dictionary
    /// walk is more robust to catalog-format drift across Xcode versions
    /// than a brittle typed model would be.
    public static func missingTranslations(
        inCatalogAt url: URL,
        for locales: [String]
    ) throws -> [MissingLocalization] {
        let data = try Data(contentsOf: url)
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let strings = root["strings"] as? [String: Any]
        else {
            throw LocalizationCatalogError.invalidCatalog
        }

        var missing: [MissingLocalization] = []

        for (key, entryAny) in strings {
            let entry = entryAny as? [String: Any]
            if (entry?["shouldTranslate"] as? Bool) == false {
                continue
            }

            let localizations = entry?["localizations"] as? [String: Any] ?? [:]

            for locale in locales {
                guard let localization = localizations[locale] as? [String: Any] else {
                    missing.append(MissingLocalization(key: key, locale: locale))
                    continue
                }

                if localization["variations"] != nil {
                    continue
                }

                let state = (localization["stringUnit"] as? [String: Any])?["state"] as? String
                if state != "translated" {
                    missing.append(MissingLocalization(key: key, locale: locale))
                }
            }
        }

        return missing
    }
}
