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
  public static let currentSchemaVersion = 1

  public var schemaVersion: Int
  public var triggerOverrides: [TriggerOverride]
  public var shortcutOverrides: [ApplicationShortcutOverride]

  public init(
    schemaVersion: Int = Self.currentSchemaVersion,
    triggerOverrides: [TriggerOverride] = [],
    shortcutOverrides: [ApplicationShortcutOverride] = []
  ) {
    self.schemaVersion = schemaVersion
    self.triggerOverrides = triggerOverrides
    self.shortcutOverrides = shortcutOverrides
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

public final class QuickDrawConfigurationStore: ShortcutOverrideProviding, @unchecked Sendable {
  private static let functionKeyCodes: Set<UInt16> = [
    122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 105, 107, 113, 106, 64, 79,
    80, 90,
  ]

  private let lock = NSLock()
  private let fileURL: URL?
  private var storedConfiguration: QuickDrawConfiguration

  public init(fileURL: URL? = QuickDrawConfigurationStore.defaultFileURL()) {
    self.fileURL = fileURL
    if let fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
      do {
        let data = try Data(contentsOf: fileURL)
        let decoded = try JSONDecoder().decode(QuickDrawConfiguration.self, from: data)
        guard decoded.schemaVersion == QuickDrawConfiguration.currentSchemaVersion else {
          throw QuickDrawConfigurationError.unsupportedSchemaVersion(decoded.schemaVersion)
        }
        storedConfiguration = decoded
      } catch {
        storedConfiguration = QuickDrawConfiguration()
      }
    } else {
      storedConfiguration = QuickDrawConfiguration()
    }
  }

  public static func defaultFileURL(fileManager: FileManager = .default) -> URL? {
    fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
      .appendingPathComponent("QuickDraw", isDirectory: true)
      .appendingPathComponent("configuration.json", isDirectory: false)
  }

  public var configuration: QuickDrawConfiguration {
    lock.withLock { storedConfiguration }
  }

  public func trigger(for action: Action) -> KeyStroke? {
    lock.withLock {
      storedConfiguration.triggerOverrides.first { $0.action == action }?.shortcut
        ?? ActionCatalog.defaultTrigger(for: action)
    }
  }

  public func isTriggerOverridden(for action: Action) -> Bool {
    lock.withLock {
      storedConfiguration.triggerOverrides.contains { $0.action == action }
    }
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

  public func validateTrigger(_ shortcut: KeyStroke, for action: Action) throws {
    let hasSafeModifier = !shortcut.modifiers.isDisjoint(with: [.command, .control, .option])
    guard Self.functionKeyCodes.contains(shortcut.virtualKeyCode) || hasSafeModifier else {
      throw QuickDrawConfigurationError.unsafeTrigger
    }

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
      if shortcut != ActionCatalog.defaultTrigger(for: action) {
        configuration.triggerOverrides.append(TriggerOverride(action: action, shortcut: shortcut))
      }
    }
  }

  public func resetTrigger(for action: Action) throws {
    try update { configuration in
      configuration.triggerOverrides.removeAll { $0.action == action }
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
      configuration.shortcutOverrides.removeAll { $0.action == action }
    }
  }

  private func update(_ change: (inout QuickDrawConfiguration) -> Void) throws {
    try lock.withLock {
      var next = storedConfiguration
      change(&next)
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
