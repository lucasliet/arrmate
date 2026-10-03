import Foundation

/// Preserves Flutter preferences when moving from the sandboxed desktop release.
enum LegacyPreferencesMigration {
  static let completionKey = "arrmate.legacySandboxPreferencesMigrated"

  /// Imports missing application keys once, keeping the original container intact.
  static func migrate(home: URL, bundleIdentifier: String, defaults: UserDefaults) throws {
    if defaults.bool(forKey: completionKey) { return }

    let source = home.appendingPathComponent(
      "Library/Containers/\(bundleIdentifier)/Data/Library/Preferences/\(bundleIdentifier).plist"
    )
    let data: Data?
    do {
      data = try Data(contentsOf: source)
    } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
      data = nil
    }
    if let data = data {
      guard let preferences = try PropertyListSerialization.propertyList(
        from: data, options: [], format: nil
      ) as? [String: Any] else {
        throw CocoaError(.propertyListReadCorrupt)
      }
      let current = defaults.persistentDomain(forName: bundleIdentifier) ?? [:]
      for (key, value) in preferences where key.hasPrefix("flutter.") && current[key] == nil {
        defaults.set(value, forKey: key)
      }
    }
    defaults.set(true, forKey: completionKey)
    // Flush before Flutter reads the domain through its preferences plugin.
    defaults.synchronize()
  }
}
