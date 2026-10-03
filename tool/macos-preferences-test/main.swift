import Foundation

let manager = FileManager.default
let home = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
let identifier = "br.com.lucasliet.arrmate.migration-test.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: identifier)!
defer {
  defaults.removePersistentDomain(forName: identifier)
  try? manager.removeItem(at: home)
}
let source = home.appendingPathComponent(
  "Library/Containers/\(identifier)/Data/Library/Preferences/\(identifier).plist"
)
try manager.createDirectory(at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
let preferences: [String: Any] = [
  "flutter.instances": "[legacy server configuration]",
  "flutter.home_tab": "series",
  "flutter.onboarding_complete": true,
  "flutter.notification_interval": 30,
  "flutter.services": ["radarr", "sonarr"],
  "unrelated.system.key": "do not import",
]
let data = try PropertyListSerialization.data(
  fromPropertyList: preferences, format: .binary, options: 0
)
try data.write(to: source)
defaults.set("movies", forKey: "flutter.home_tab")

try LegacyPreferencesMigration.migrate(home: home, bundleIdentifier: identifier, defaults: defaults)
precondition(defaults.string(forKey: "flutter.instances") == preferences["flutter.instances"] as? String)
precondition(defaults.string(forKey: "flutter.home_tab") == "movies")
precondition(defaults.bool(forKey: "flutter.onboarding_complete"))
precondition(defaults.integer(forKey: "flutter.notification_interval") == 30)
precondition(defaults.stringArray(forKey: "flutter.services") == ["radarr", "sonarr"])
precondition(defaults.object(forKey: "unrelated.system.key") == nil)
let preservedData = try Data(contentsOf: source)
precondition(preservedData == data)

// Clearing settings after migration must not resurrect the old server configuration.
defaults.removeObject(forKey: "flutter.instances")
try LegacyPreferencesMigration.migrate(home: home, bundleIdentifier: identifier, defaults: defaults)
precondition(defaults.object(forKey: "flutter.instances") == nil)

// Failed reads remain retryable without marking migration complete or changing settings.
defaults.removeObject(forKey: LegacyPreferencesMigration.completionKey)
try Data("invalid plist".utf8).write(to: source)
var rejected = false
do {
  try LegacyPreferencesMigration.migrate(home: home, bundleIdentifier: identifier, defaults: defaults)
} catch {
  rejected = true
}
precondition(rejected)
precondition(!defaults.bool(forKey: LegacyPreferencesMigration.completionKey))
precondition(defaults.string(forKey: "flutter.home_tab") == "movies")
try data.write(to: source)
try LegacyPreferencesMigration.migrate(home: home, bundleIdentifier: identifier, defaults: defaults)
precondition(defaults.string(forKey: "flutter.instances") != nil)

// A fresh installation succeeds without creating a legacy container.
defaults.removeObject(forKey: LegacyPreferencesMigration.completionKey)
try manager.removeItem(at: source)
try LegacyPreferencesMigration.migrate(home: home, bundleIdentifier: identifier, defaults: defaults)
precondition(defaults.bool(forKey: LegacyPreferencesMigration.completionKey))

// Both development and release apps must be able to stage and launch their updater.
for name in ["DebugProfile", "Release"] {
  let entitlement = try Data(contentsOf: URL(fileURLWithPath: "macos/Runner/\(name).entitlements"))
  let values = try PropertyListSerialization.propertyList(
    from: entitlement, options: [], format: nil
  ) as! [String: Any]
  precondition(values["com.apple.security.app-sandbox"] as? Bool != true)
}
