import Foundation

enum RinvioDefaultsMigration {
  static let legacyBundleIdentifier = "com.keishingu.quickdraw-shortcuts"
  private static let completionKey = "didMigrateQuickDrawDefaults"
  private static let migratedKeys = [
    AppLanguage.defaultsKey,
    "cheatSheetEnabled",
    "developerModeEnabled",
  ]

  static func migrateIfNeeded(
    defaults: UserDefaults = .standard,
    legacyDomain: [String: Any]? = nil
  ) {
    guard !defaults.bool(forKey: completionKey) else { return }
    guard
      let legacyDomain = legacyDomain
        ?? UserDefaults.standard.persistentDomain(forName: legacyBundleIdentifier)
    else { return }

    for key in migratedKeys where defaults.object(forKey: key) == nil {
      if let value = legacyDomain[key] {
        defaults.set(value, forKey: key)
      }
    }
    defaults.set(true, forKey: completionKey)
  }
}
