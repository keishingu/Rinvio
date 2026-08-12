import Foundation
import QuickDrawCore

struct TriggerAlignmentResult: Equatable {
  let appliedCount: Int
  let skippedDuplicateCount: Int
  let error: String?
}

final class HotKeyConfigurationCoordinator {
  private let registrar: GlobalHotKeyRegistrar
  private let store: QuickDrawConfigurationStore
  private var handler: (([Action]) -> Bool)?
  private var modifierHandler: ((Set<ModifierKey>) -> Void)?
  private var nonModifierKeyHandler: (() -> Void)?

  init(registrar: GlobalHotKeyRegistrar, store: QuickDrawConfigurationStore) {
    self.registrar = registrar
    self.store = store
  }

  func start(
    handler: @escaping ([Action]) -> Bool,
    modifierHandler: @escaping (Set<ModifierKey>) -> Void,
    nonModifierKeyHandler: @escaping () -> Void
  ) throws {
    self.handler = handler
    self.modifierHandler = modifierHandler
    self.nonModifierKeyHandler = nonModifierKeyHandler
    try registrar.register(
      bindings: currentBindings(),
      handler: handler,
      modifierHandler: modifierHandler,
      nonModifierKeyHandler: nonModifierKeyHandler
    )
  }

  func suspend() {
    registrar.unregister()
  }

  @discardableResult
  func resume() -> String? {
    guard let handler, let modifierHandler, let nonModifierKeyHandler else {
      return "Global shortcut handler is unavailable"
    }
    do {
      try registrar.register(
        bindings: currentBindings(),
        handler: handler,
        modifierHandler: modifierHandler,
        nonModifierKeyHandler: nonModifierKeyHandler
      )
      return nil
    } catch {
      return error.localizedDescription
    }
  }

  func applyTrigger(_ shortcut: KeyStroke, for action: Action) -> String? {
    do {
      try store.validateTrigger(shortcut, for: action)
    } catch {
      _ = resume()
      return error.localizedDescription
    }

    var nextBindings = currentBindings()
    if !ActionCatalog.isSystemWide(action) {
      nextBindings[action] = shortcut
    }
    guard let handler, let modifierHandler, let nonModifierKeyHandler else {
      return "Global shortcut handler is unavailable"
    }

    do {
      try registrar.register(
        bindings: nextBindings,
        handler: handler,
        modifierHandler: modifierHandler,
        nonModifierKeyHandler: nonModifierKeyHandler
      )
      do {
        try store.setTriggerOverride(shortcut, for: action)
        return nil
      } catch {
        _ = resume()
        return error.localizedDescription
      }
    } catch {
      _ = resume()
      return error.localizedDescription
    }
  }

  func resetTrigger(for action: Action) -> String? {
    guard let handler, let modifierHandler, let nonModifierKeyHandler else {
      return "Global shortcut handler is unavailable"
    }
    var nextBindings = currentBindings()
    if !ActionCatalog.isSystemWide(action) {
      nextBindings[action] = ActionCatalog.defaultTrigger(for: action)
    }
    do {
      try registrar.register(
        bindings: nextBindings,
        handler: handler,
        modifierHandler: modifierHandler,
        nonModifierKeyHandler: nonModifierKeyHandler
      )
      try store.resetTrigger(for: action)
      return nil
    } catch {
      _ = resume()
      return error.localizedDescription
    }
  }

  func unassignTrigger(for action: Action) -> String? {
    guard let handler, let modifierHandler, let nonModifierKeyHandler else {
      return "Global shortcut handler is unavailable"
    }
    var nextBindings = currentBindings()
    nextBindings.removeValue(forKey: action)
    do {
      try registrar.register(
        bindings: nextBindings,
        handler: handler,
        modifierHandler: modifierHandler,
        nonModifierKeyHandler: nonModifierKeyHandler
      )
      try store.unassignTrigger(for: action)
      return nil
    } catch {
      _ = resume()
      return error.localizedDescription
    }
  }

  func alignDevelopmentTriggers(to target: ActionTarget) -> TriggerAlignmentResult {
    guard let handler, let modifierHandler, let nonModifierKeyHandler else {
      return TriggerAlignmentResult(
        appliedCount: 0,
        skippedDuplicateCount: 0,
        error: "Global shortcut handler is unavailable"
      )
    }

    var shortcuts: [Action: KeyStroke] = [:]
    var usedShortcuts: Set<PhysicalShortcut> = []
    var skippedDuplicateCount = 0
    for action in Action.allCases where action.domain == .development {
      guard let shortcut = store.shortcut(for: action, target: target) else { continue }
      if usedShortcuts.insert(PhysicalShortcut(shortcut)).inserted {
        shortcuts[action] = shortcut
      } else {
        skippedDuplicateCount += 1
      }
    }

    var nextBindings = currentBindings()
    nextBindings.merge(shortcuts) { _, aligned in aligned }
    while let conflict = firstConflict(in: nextBindings) {
      let actionToKeep = shortcuts[conflict.0] == nil ? conflict.0 : conflict.1
      let actionToSkip = actionToKeep == conflict.0 ? conflict.1 : conflict.0
      guard shortcuts.removeValue(forKey: actionToSkip) != nil else { break }
      nextBindings[actionToSkip] = store.trigger(for: actionToSkip)
      skippedDuplicateCount += 1
    }
    do {
      try registrar.register(
        bindings: nextBindings,
        handler: handler,
        modifierHandler: modifierHandler,
        nonModifierKeyHandler: nonModifierKeyHandler
      )
      do {
        try store.setTriggerOverrides(shortcuts)
        return TriggerAlignmentResult(
          appliedCount: shortcuts.count,
          skippedDuplicateCount: skippedDuplicateCount,
          error: nil
        )
      } catch {
        _ = resume()
        return TriggerAlignmentResult(
          appliedCount: 0,
          skippedDuplicateCount: skippedDuplicateCount,
          error: error.localizedDescription
        )
      }
    } catch {
      _ = resume()
      return TriggerAlignmentResult(
        appliedCount: 0,
        skippedDuplicateCount: skippedDuplicateCount,
        error: error.localizedDescription
      )
    }
  }

  func resetAction(_ action: Action) -> String? {
    guard let handler, let modifierHandler, let nonModifierKeyHandler else {
      return "Global shortcut handler is unavailable"
    }
    var nextBindings = currentBindings()
    if !ActionCatalog.isSystemWide(action) {
      nextBindings[action] = ActionCatalog.defaultTrigger(for: action)
    }
    do {
      try registrar.register(
        bindings: nextBindings,
        handler: handler,
        modifierHandler: modifierHandler,
        nonModifierKeyHandler: nonModifierKeyHandler
      )
      try store.resetAction(action)
      return nil
    } catch {
      _ = resume()
      return error.localizedDescription
    }
  }

  private func currentBindings() -> [Action: KeyStroke] {
    Dictionary(
      uniqueKeysWithValues: Action.allCases.compactMap { action in
        if ActionCatalog.isSystemWide(action) { return nil }
        return store.trigger(for: action).map { (action, $0) }
      }
    )
  }

  private func firstConflict(in bindings: [Action: KeyStroke]) -> (Action, Action)? {
    for (index, action) in Action.allCases.enumerated() {
      guard let shortcut = bindings[action] else { continue }
      if let duplicate = Action.allCases.dropFirst(index + 1).first(where: { candidate in
        ActionCatalog.triggerScopesOverlap(action, candidate)
          && bindings[candidate]?.matchesPhysicalShortcut(shortcut) == true
      }) {
        return (action, duplicate)
      }
    }
    return nil
  }
}

private struct PhysicalShortcut: Hashable {
  let virtualKeyCode: UInt16
  let modifiers: Set<ModifierKey>

  init(_ shortcut: KeyStroke) {
    virtualKeyCode = shortcut.virtualKeyCode
    modifiers = shortcut.modifiers
  }
}
