import Foundation

public struct TriggerOverride: Codable, Equatable, Sendable {
  public let action: Action
  public let shortcut: KeyStroke

  public init(action: Action, shortcut: KeyStroke) {
    self.action = action
    self.shortcut = shortcut
  }
}

public struct ApplicationShortcutOverride: Codable, Equatable, Sendable {
  public let action: Action
  public let target: ActionTarget
  public let shortcut: KeyStroke

  public init(action: Action, target: ActionTarget, shortcut: KeyStroke) {
    self.action = action
    self.target = target
    self.shortcut = shortcut
  }
}

public struct QuickDrawConfiguration: Codable, Equatable, Sendable {
  public static let currentSchemaVersion = 2

  public var schemaVersion: Int
  public var triggerOverrides: [TriggerOverride]
  public var unassignedTriggers: [Action]
  public var shortcutOverrides: [ApplicationShortcutOverride]
  public var disabledApplications: [ActionTarget]
  public var enabledOptInTargets: [ActionTarget]

  public init(
    schemaVersion: Int = Self.currentSchemaVersion,
    triggerOverrides: [TriggerOverride] = [],
    unassignedTriggers: [Action] = [],
    shortcutOverrides: [ApplicationShortcutOverride] = [],
    disabledApplications: [ActionTarget] = [],
    enabledOptInTargets: [ActionTarget] = []
  ) {
    self.schemaVersion = schemaVersion
    self.triggerOverrides = triggerOverrides
    self.unassignedTriggers = unassignedTriggers
    self.shortcutOverrides = shortcutOverrides
    self.disabledApplications = disabledApplications
    self.enabledOptInTargets = enabledOptInTargets
  }

  private enum CodingKeys: String, CodingKey {
    case schemaVersion
    case triggerOverrides
    case unassignedTriggers
    case shortcutOverrides
    case disabledApplications
    case enabledOptInTargets
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    triggerOverrides = try container.decode([TriggerOverride].self, forKey: .triggerOverrides)
    unassignedTriggers =
      try container.decodeIfPresent(
        [Action].self,
        forKey: .unassignedTriggers
      ) ?? []
    shortcutOverrides = try container.decode(
      [ApplicationShortcutOverride].self,
      forKey: .shortcutOverrides
    )
    disabledApplications =
      try container.decodeIfPresent(
        [ActionTarget].self,
        forKey: .disabledApplications
      ) ?? []
    enabledOptInTargets =
      try container.decodeIfPresent(
        [ActionTarget].self,
        forKey: .enabledOptInTargets
      ) ?? []
  }
}

public enum QuickDrawConfigurationError: LocalizedError, Equatable {
  case unsupportedSchemaVersion(Int)
  case unsafeTrigger
  case duplicateTrigger(Action)

  public var errorDescription: String? {
    switch self {
    case .unsupportedSchemaVersion(let version):
      "Configuration schema version \(version) is not supported"
    case .unsafeTrigger:
      "Use a function key or a shortcut containing Command, Control, or Option"
    case .duplicateTrigger(let action):
      "This trigger is already assigned to \(action.displayName)"
    }
  }
}

public final class QuickDrawConfigurationStore: ShortcutOverrideProviding,
  ApplicationEnablementProviding, @unchecked Sendable
{
  private static let developmentBundleIdentifier = "com.keishingu.rinvio.dev"
  private static let functionKeyCodes: Set<UInt16> = [
    122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 105, 107, 113, 106, 64, 79,
    80, 90,
  ]

  private let lock = NSLock()
  private let fileURL: URL?
  private var storedConfiguration: QuickDrawConfiguration

  public convenience init(bundleIdentifier: String? = Bundle.main.bundleIdentifier) {
    self.init(
      fileURL: Self.defaultFileURL(bundleIdentifier: bundleIdentifier),
      legacyFileURL: Self.legacyDefaultFileURL(bundleIdentifier: bundleIdentifier)
    )
  }

  public convenience init(fileURL: URL?) {
    self.init(fileURL: fileURL, legacyFileURL: nil)
  }

  public init(fileURL: URL?, legacyFileURL: URL?) {
    self.fileURL = fileURL
    let sourceURL: URL?
    let isMigratingLegacyConfiguration: Bool
    if let fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
      sourceURL = fileURL
      isMigratingLegacyConfiguration = false
    } else if let legacyFileURL, FileManager.default.fileExists(atPath: legacyFileURL.path) {
      sourceURL = legacyFileURL
      isMigratingLegacyConfiguration = true
    } else {
      sourceURL = nil
      isMigratingLegacyConfiguration = false
    }

    if let sourceURL {
      do {
        let data = try Data(contentsOf: sourceURL)
        let decoded = try JSONDecoder().decode(QuickDrawConfiguration.self, from: data)
        let migrated = try Self.migrate(decoded)
        storedConfiguration = migrated
        if isMigratingLegacyConfiguration || migrated != decoded {
          try? persist(migrated)
        }
      } catch {
        storedConfiguration = QuickDrawConfiguration()
      }
    } else {
      storedConfiguration = QuickDrawConfiguration()
    }
  }

  public static func defaultFileURL(
    fileManager: FileManager = .default,
    bundleIdentifier: String? = Bundle.main.bundleIdentifier
  ) -> URL? {
    let directoryName =
      bundleIdentifier == developmentBundleIdentifier ? "Rinvio Dev" : "Rinvio"
    return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
      .appendingPathComponent(directoryName, isDirectory: true)
      .appendingPathComponent("configuration.json", isDirectory: false)
  }

  public static func legacyDefaultFileURL(
    fileManager: FileManager = .default,
    bundleIdentifier: String? = Bundle.main.bundleIdentifier
  ) -> URL? {
    guard bundleIdentifier != developmentBundleIdentifier else { return nil }
    return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
      .appendingPathComponent("QuickDraw", isDirectory: true)
      .appendingPathComponent("configuration.json", isDirectory: false)
  }

  public var configuration: QuickDrawConfiguration {
    lock.withLock { storedConfiguration }
  }

  public func trigger(for action: Action) -> KeyStroke? {
    lock.withLock {
      guard !storedConfiguration.unassignedTriggers.contains(action) else { return nil }
      return storedConfiguration.triggerOverrides.first { $0.action == action }?.shortcut
        ?? ActionCatalog.defaultTrigger(for: action)
    }
  }

  public func isTriggerOverridden(for action: Action) -> Bool {
    lock.withLock {
      storedConfiguration.unassignedTriggers.contains(action)
        || storedConfiguration.triggerOverrides.contains { $0.action == action }
    }
  }

  public func actions(withTriggerModifiers modifiers: Set<ModifierKey>) -> [Action] {
    Action.allCases.filter { trigger(for: $0)?.modifiers == modifiers }
  }

  public func actions(
    withApplicationShortcutModifiers modifiers: Set<ModifierKey>,
    for target: ActionTarget
  ) -> [Action] {
    Action.allCases.filter { shortcut(for: $0, target: target)?.modifiers == modifiers }
  }

  public func shortcut(for action: Action, target: ActionTarget) -> KeyStroke? {
    shortcutOverride(for: action, target: target)
      ?? ActionCatalog.defaultShortcut(for: action, target: target)
  }

  public func shortcutOverride(for action: Action, target: ActionTarget) -> KeyStroke? {
    lock.withLock {
      storedConfiguration.shortcutOverrides.first {
        $0.action == action && $0.target == target
      }?.shortcut
    }
  }

  public func isShortcutOverridden(for action: Action, target: ActionTarget) -> Bool {
    shortcutOverride(for: action, target: target) != nil
  }

  public func isApplicationEnabled(_ target: ActionTarget) -> Bool {
    lock.withLock {
      if target == .macOS { return false }
      if Self.optInTargets.contains(target) {
        return storedConfiguration.enabledOptInTargets.contains(target)
      }
      return !storedConfiguration.disabledApplications.contains(target)
    }
  }

  public func setApplicationEnabled(
    _ enabled: Bool,
    for target: ActionTarget
  ) throws {
    try update { configuration in
      if target == .macOS {
        configuration.enabledOptInTargets.removeAll { $0 == .macOS }
        return
      }
      if Self.optInTargets.contains(target) {
        configuration.enabledOptInTargets.removeAll { $0 == target }
        if enabled {
          configuration.enabledOptInTargets.append(target)
          configuration.enabledOptInTargets.sort { $0.rawValue < $1.rawValue }
        }
        return
      }
      configuration.disabledApplications.removeAll { $0 == target }
      if !enabled {
        configuration.disabledApplications.append(target)
        configuration.disabledApplications.sort { $0.rawValue < $1.rawValue }
      }
    }
  }

  public func validateTrigger(_ shortcut: KeyStroke, for action: Action) throws {
    try Self.validateTriggerSafety(shortcut)

    if let duplicate = Action.allCases.first(where: { candidate in
      candidate != action
        && ActionCatalog.triggerScopesOverlap(action, candidate)
        && trigger(for: candidate)?.matchesPhysicalShortcut(shortcut) == true
    }) {
      throw QuickDrawConfigurationError.duplicateTrigger(duplicate)
    }
  }

  public func setTriggerOverride(_ shortcut: KeyStroke, for action: Action) throws {
    try validateTrigger(shortcut, for: action)
    try update { configuration in
      configuration.triggerOverrides.removeAll { $0.action == action }
      configuration.unassignedTriggers.removeAll { $0 == action }
      if shortcut != ActionCatalog.defaultTrigger(for: action) {
        configuration.triggerOverrides.append(TriggerOverride(action: action, shortcut: shortcut))
      }
    }
  }

  public func setTriggerOverrides(_ shortcuts: [Action: KeyStroke]) throws {
    try update { configuration in
      for (action, shortcut) in shortcuts {
        try Self.validateTriggerSafety(shortcut)
        configuration.triggerOverrides.removeAll { $0.action == action }
        configuration.unassignedTriggers.removeAll { $0 == action }
        if shortcut != ActionCatalog.defaultTrigger(for: action) {
          configuration.triggerOverrides.append(
            TriggerOverride(action: action, shortcut: shortcut)
          )
        }
      }

      for (index, action) in Action.allCases.enumerated() {
        guard let trigger = Self.trigger(for: action, in: configuration) else { continue }
        if let duplicate = Action.allCases.dropFirst(index + 1).first(where: { candidate in
          ActionCatalog.triggerScopesOverlap(action, candidate)
            && Self.trigger(for: candidate, in: configuration)?
              .matchesPhysicalShortcut(trigger) == true
        }) {
          throw QuickDrawConfigurationError.duplicateTrigger(duplicate)
        }
      }
    }
  }

  public func unassignTrigger(for action: Action) throws {
    try update { configuration in
      configuration.triggerOverrides.removeAll { $0.action == action }
      configuration.unassignedTriggers.removeAll { $0 == action }
      configuration.unassignedTriggers.append(action)
      configuration.unassignedTriggers.sort { $0.rawValue < $1.rawValue }
    }
  }

  public func resetTrigger(for action: Action) throws {
    try update { configuration in
      configuration.triggerOverrides.removeAll { $0.action == action }
      configuration.unassignedTriggers.removeAll { $0 == action }
    }
  }

  public func setShortcutOverride(
    _ shortcut: KeyStroke,
    for action: Action,
    target: ActionTarget
  ) throws {
    try update { configuration in
      configuration.shortcutOverrides.removeAll {
        $0.action == action && $0.target == target
      }
      if shortcut != ActionCatalog.defaultShortcut(for: action, target: target) {
        configuration.shortcutOverrides.append(
          ApplicationShortcutOverride(action: action, target: target, shortcut: shortcut)
        )
      }
    }
  }

  public func resetShortcut(for action: Action, target: ActionTarget) throws {
    try update { configuration in
      configuration.shortcutOverrides.removeAll {
        $0.action == action && $0.target == target
      }
    }
  }

  public func resetAction(_ action: Action) throws {
    try update { configuration in
      configuration.triggerOverrides.removeAll { $0.action == action }
      configuration.unassignedTriggers.removeAll { $0 == action }
      configuration.shortcutOverrides.removeAll { $0.action == action }
    }
  }

  private static func validateTriggerSafety(_ shortcut: KeyStroke) throws {
    let hasSafeModifier = !shortcut.modifiers.isDisjoint(with: [.command, .control, .option])
    guard functionKeyCodes.contains(shortcut.virtualKeyCode) || hasSafeModifier else {
      throw QuickDrawConfigurationError.unsafeTrigger
    }
  }

  private static let optInTargets: Set<ActionTarget> = [.finder]

  private static func migrate(_ configuration: QuickDrawConfiguration) throws
    -> QuickDrawConfiguration
  {
    guard configuration.schemaVersion <= QuickDrawConfiguration.currentSchemaVersion else {
      throw QuickDrawConfigurationError.unsupportedSchemaVersion(configuration.schemaVersion)
    }
    guard configuration.schemaVersion < QuickDrawConfiguration.currentSchemaVersion else {
      return configuration
    }

    var migrated = configuration
    if migrated.schemaVersion == 1 {
      for action in Action.allCases {
        guard let legacyTrigger = legacySuggestedTriggers[action] else { continue }
        guard
          !migrated.unassignedTriggers.contains(action),
          !migrated.triggerOverrides.contains(where: { $0.action == action })
        else { continue }
        migrated.triggerOverrides.append(
          TriggerOverride(action: action, shortcut: legacyTrigger)
        )
      }
      migrated.enabledOptInTargets = []
      migrated.schemaVersion = 2
    } else {
      throw QuickDrawConfigurationError.unsupportedSchemaVersion(migrated.schemaVersion)
    }
    return migrated
  }

  private static let legacySuggestedTriggers: [Action: KeyStroke] = {
    func key(_ code: UInt16, _ modifiers: Set<ModifierKey>, _ display: String) -> KeyStroke {
      KeyStroke(virtualKeyCode: code, modifiers: modifiers, displayValue: display)
    }
    return [
      .mute: key(46, [.command, .option], "⌘⌥M"),
      .camera: key(8, [.command, .option], "⌘⌥C"),
      .raiseHand: key(4, [.command, .option], "⌘⌥H"),
      .openChat: key(31, [.command, .option], "⌘⌥O"),
      .showParticipants: key(35, [.command, .option], "⌘⌥P"),
      .toggleCaptions: key(37, [.command, .option], "⌘⌥L"),
      .shareScreen: key(1, [.command, .option], "⌘⌥S"),
      .switchCamera: key(7, [.command, .option], "⌘⌥X"),
      .pictureInPicture: key(34, [.command, .option], "⌘⌥I"),
      .leaveMeeting: key(5, [.command, .option], "⌘⌥G"),
      .reactionLike: key(18, [.command, .option], "⌘⌥1"),
      .reactionHeart: key(19, [.command, .option], "⌘⌥2"),
      .reactionClap: key(20, [.command, .option], "⌘⌥3"),
      .reactionLaugh: key(21, [.command, .option], "⌘⌥4"),
      .reactionWow: key(23, [.command, .option], "⌘⌥5"),
      .reactionCelebrate: key(22, [.command, .option], "⌘⌥6"),
      .newSession: key(45, [.command, .option], "⌘⌥N"),
      .toggleTerminal: key(17, [.command, .option], "⌘⌥T"),
      .focusSidebar: key(122, [.command, .option], "⌘⌥F1"),
      .focusMainColumn: key(120, [.command, .option], "⌘⌥F2"),
      .focusTerminal: key(99, [.command, .option], "⌘⌥F3"),
      .commandPalette: key(40, [.command, .option], "⌘⌥K"),
      .quickOpen: key(12, [.command, .option], "⌘⌥Q"),
      .hardReload: key(15, [.command, .option], "⌘⌥R"),
      .nextTab: key(30, [.command, .option], "⌘⌥]"),
      .previousTab: key(33, [.command, .option], "⌘⌥["),
      .openDownloads: key(2, [.command, .option], "⌘⌥D"),
      .openDeveloperTools: key(14, [.command, .option], "⌘⌥E"),
      .reopenClosedTab: key(6, [.command, .option], "⌘⌥Z"),
    ]
  }()

  private static func trigger(
    for action: Action,
    in configuration: QuickDrawConfiguration
  ) -> KeyStroke? {
    guard !configuration.unassignedTriggers.contains(action) else { return nil }
    return configuration.triggerOverrides.first { $0.action == action }?.shortcut
      ?? ActionCatalog.defaultTrigger(for: action)
  }

  private func update(_ change: (inout QuickDrawConfiguration) throws -> Void) throws {
    try lock.withLock {
      var next = storedConfiguration
      try change(&next)
      try persist(next)
      storedConfiguration = next
    }
  }

  private func persist(_ configuration: QuickDrawConfiguration) throws {
    guard let fileURL else { return }
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(configuration).write(to: fileURL, options: .atomic)
  }
}

extension KeyStroke {
  public func matchesPhysicalShortcut(_ other: KeyStroke) -> Bool {
    virtualKeyCode == other.virtualKeyCode && modifiers == other.modifiers
  }
}
