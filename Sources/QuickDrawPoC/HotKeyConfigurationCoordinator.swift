import Foundation
import QuickDrawCore

final class HotKeyConfigurationCoordinator {
  private let registrar: GlobalHotKeyRegistrar
  private let store: QuickDrawConfigurationStore
  private var handler: ((MeetingAction) -> Void)?

  init(registrar: GlobalHotKeyRegistrar, store: QuickDrawConfigurationStore) {
    self.registrar = registrar
    self.store = store
  }

  func start(handler: @escaping (MeetingAction) -> Void) throws {
    self.handler = handler
    try registrar.register(bindings: currentBindings(), handler: handler)
  }

  func suspend() {
    registrar.unregister()
  }

  @discardableResult
  func resume() -> String? {
    guard let handler else { return "Global shortcut handler is unavailable" }
    do {
      try registrar.register(bindings: currentBindings(), handler: handler)
      return nil
    } catch {
      return error.localizedDescription
    }
  }

  func applyTrigger(_ shortcut: KeyStroke, for action: MeetingAction) -> String? {
    do {
      try store.validateTrigger(shortcut, for: action)
    } catch {
      _ = resume()
      return error.localizedDescription
    }

    var nextBindings = currentBindings()
    nextBindings[action] = shortcut
    guard let handler else { return "Global shortcut handler is unavailable" }

    do {
      try registrar.register(bindings: nextBindings, handler: handler)
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

  func resetTrigger(for action: MeetingAction) -> String? {
    guard let handler else { return "Global shortcut handler is unavailable" }
    var nextBindings = currentBindings()
    nextBindings[action] = ActionCatalog.defaultTrigger(for: action)
    do {
      try registrar.register(bindings: nextBindings, handler: handler)
      try store.resetTrigger(for: action)
      return nil
    } catch {
      _ = resume()
      return error.localizedDescription
    }
  }

  func resetAction(_ action: MeetingAction) -> String? {
    guard let handler else { return "Global shortcut handler is unavailable" }
    var nextBindings = currentBindings()
    nextBindings[action] = ActionCatalog.defaultTrigger(for: action)
    do {
      try registrar.register(bindings: nextBindings, handler: handler)
      try store.resetAction(action)
      return nil
    } catch {
      _ = resume()
      return error.localizedDescription
    }
  }

  private func currentBindings() -> [MeetingAction: KeyStroke] {
    Dictionary(
      uniqueKeysWithValues: MeetingAction.allCases.compactMap { action in
        store.trigger(for: action).map { (action, $0) }
      }
    )
  }
}
