import Foundation
import QuickDrawCore

final class HotKeyConfigurationCoordinator {
  private let registrar: GlobalHotKeyRegistrar
  private let store: QuickDrawConfigurationStore
  private var handler: (([Action]) -> Bool)?
  private var modifierHandler: ((Set<ModifierKey>) -> Void)?

  init(registrar: GlobalHotKeyRegistrar, store: QuickDrawConfigurationStore) {
    self.registrar = registrar
    self.store = store
  }

  func start(
    handler: @escaping ([Action]) -> Bool,
    modifierHandler: @escaping (Set<ModifierKey>) -> Void
  ) throws {
    self.handler = handler
    self.modifierHandler = modifierHandler
    try registrar.register(
      bindings: currentBindings(),
      handler: handler,
      modifierHandler: modifierHandler
    )
  }

  func suspend() {
    registrar.unregister()
  }

  @discardableResult
  func resume() -> String? {
    guard let handler, let modifierHandler else {
      return "Global shortcut handler is unavailable"
    }
    do {
      try registrar.register(
        bindings: currentBindings(),
        handler: handler,
        modifierHandler: modifierHandler
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
    nextBindings[action] = shortcut
    guard let handler, let modifierHandler else {
      return "Global shortcut handler is unavailable"
    }

    do {
      try registrar.register(
        bindings: nextBindings,
        handler: handler,
        modifierHandler: modifierHandler
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
    guard let handler, let modifierHandler else {
      return "Global shortcut handler is unavailable"
    }
    var nextBindings = currentBindings()
    nextBindings[action] = ActionCatalog.defaultTrigger(for: action)
    do {
      try registrar.register(
        bindings: nextBindings,
        handler: handler,
        modifierHandler: modifierHandler
      )
      try store.resetTrigger(for: action)
      return nil
    } catch {
      _ = resume()
      return error.localizedDescription
    }
  }

  func resetAction(_ action: Action) -> String? {
    guard let handler, let modifierHandler else {
      return "Global shortcut handler is unavailable"
    }
    var nextBindings = currentBindings()
    nextBindings[action] = ActionCatalog.defaultTrigger(for: action)
    do {
      try registrar.register(
        bindings: nextBindings,
        handler: handler,
        modifierHandler: modifierHandler
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
        store.trigger(for: action).map { (action, $0) }
      }
    )
  }
}
