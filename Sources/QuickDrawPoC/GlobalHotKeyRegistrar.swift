import Carbon
import Foundation
import QuickDrawCore

enum GlobalHotKeyError: LocalizedError {
  case eventHandlerInstallationFailed(OSStatus)
  case registrationFailed(action: MeetingAction, shortcut: String, status: OSStatus)

  var errorDescription: String? {
    switch self {
    case .eventHandlerInstallationFailed(let status):
      "Could not install the global hotkey handler (OSStatus \(status))"
    case .registrationFailed(let action, let shortcut, let status):
      "\(shortcut) for \(action.displayName) could not be registered (OSStatus \(status))"
    }
  }
}

final class GlobalHotKeyRegistrar {
  private struct HotKeyDefinition {
    let id: UInt32
    let action: MeetingAction
    let shortcut: KeyStroke
  }

  private static let signature: OSType = 0x5144_5043  // QDPC

  private var eventHandlerRef: EventHandlerRef?
  private var hotKeyRefs: [EventHotKeyRef] = []
  private var handler: ((MeetingAction) -> Void)?
  private var pressGates: [UInt32: TriggerPressGate] = [:]
  private var definitionsByID: [UInt32: HotKeyDefinition] = [:]

  func register(
    bindings: [MeetingAction: KeyStroke],
    handler: @escaping (MeetingAction) -> Void
  ) throws {
    unregister()
    self.handler = handler
    let definitions = MeetingAction.allCases.enumerated().map { index, action in
      HotKeyDefinition(
        id: UInt32(index + 1),
        action: action,
        shortcut: bindings[action] ?? ActionCatalog.defaultTrigger(for: action)
      )
    }
    definitionsByID = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) })
    pressGates = Dictionary(
      uniqueKeysWithValues: definitions.map { ($0.id, TriggerPressGate()) }
    )

    var eventTypes = [
      EventTypeSpec(
        eventClass: OSType(kEventClassKeyboard),
        eventKind: UInt32(kEventHotKeyPressed)
      ),
      EventTypeSpec(
        eventClass: OSType(kEventClassKeyboard),
        eventKind: UInt32(kEventHotKeyReleased)
      ),
    ]

    let userData = Unmanaged.passUnretained(self).toOpaque()
    let installStatus = InstallEventHandler(
      GetApplicationEventTarget(),
      { _, event, userData in
        guard let event, let userData else {
          return OSStatus(eventNotHandledErr)
        }

        let registrar = Unmanaged<GlobalHotKeyRegistrar>
          .fromOpaque(userData)
          .takeUnretainedValue()

        var hotKeyID = EventHotKeyID()
        let readStatus = GetEventParameter(
          event,
          EventParamName(kEventParamDirectObject),
          EventParamType(typeEventHotKeyID),
          nil,
          MemoryLayout<EventHotKeyID>.size,
          nil,
          &hotKeyID
        )
        guard readStatus == noErr,
          hotKeyID.signature == GlobalHotKeyRegistrar.signature,
          let definition = registrar.definitionsByID[hotKeyID.id]
        else {
          return OSStatus(eventNotHandledErr)
        }

        guard var gate = registrar.pressGates[definition.id] else {
          return OSStatus(eventNotHandledErr)
        }

        switch GetEventKind(event) {
        case UInt32(kEventHotKeyPressed):
          let shouldInvoke = gate.shouldInvoke(for: .pressed)
          registrar.pressGates[definition.id] = gate
          if shouldInvoke {
            registrar.handler?(definition.action)
          }
        case UInt32(kEventHotKeyReleased):
          _ = gate.shouldInvoke(for: .released)
          registrar.pressGates[definition.id] = gate
        default:
          return OSStatus(eventNotHandledErr)
        }
        return noErr
      },
      eventTypes.count,
      &eventTypes,
      userData,
      &eventHandlerRef
    )

    guard installStatus == noErr else {
      self.handler = nil
      throw GlobalHotKeyError.eventHandlerInstallationFailed(installStatus)
    }

    for definition in definitions {
      var hotKeyRef: EventHotKeyRef?
      let hotKeyID = EventHotKeyID(signature: Self.signature, id: definition.id)
      let status = RegisterEventHotKey(
        UInt32(definition.shortcut.virtualKeyCode),
        carbonModifiers(for: definition.shortcut.modifiers),
        hotKeyID,
        GetApplicationEventTarget(),
        0,
        &hotKeyRef
      )

      guard status == noErr, let hotKeyRef else {
        unregister()
        throw GlobalHotKeyError.registrationFailed(
          action: definition.action,
          shortcut: definition.shortcut.displayValue,
          status: status
        )
      }
      hotKeyRefs.append(hotKeyRef)
    }
  }

  func unregister() {
    for hotKeyRef in hotKeyRefs {
      UnregisterEventHotKey(hotKeyRef)
    }
    if let eventHandlerRef {
      RemoveEventHandler(eventHandlerRef)
    }
    hotKeyRefs = []
    eventHandlerRef = nil
    handler = nil
    pressGates = [:]
    definitionsByID = [:]
  }

  private func carbonModifiers(for modifiers: Set<ModifierKey>) -> UInt32 {
    var result: UInt32 = 0
    if modifiers.contains(.command) { result |= UInt32(cmdKey) }
    if modifiers.contains(.shift) { result |= UInt32(shiftKey) }
    if modifiers.contains(.control) { result |= UInt32(controlKey) }
    if modifiers.contains(.option) { result |= UInt32(optionKey) }
    return result
  }

  deinit {
    unregister()
  }
}
