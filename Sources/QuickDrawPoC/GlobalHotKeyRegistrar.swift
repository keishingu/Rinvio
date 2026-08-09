import Carbon
import Foundation
import QuickDrawCore

enum GlobalHotKeyError: LocalizedError {
  case eventHandlerInstallationFailed(OSStatus)
  case registrationFailed(action: MeetingAction, status: OSStatus)

  var errorDescription: String? {
    switch self {
    case .eventHandlerInstallationFailed(let status):
      "Could not install the global hotkey handler (OSStatus \(status))"
    case .registrationFailed(let action, let status):
      "\(action.triggerDisplayValue) could not be registered (OSStatus \(status))"
    }
  }
}

final class GlobalHotKeyRegistrar {
  private struct HotKeyDefinition {
    let id: UInt32
    let action: MeetingAction
    let keyCode: UInt32
  }

  private static let signature: OSType = 0x5144_5043  // QDPC
  private static let definitions = [
    HotKeyDefinition(id: 1, action: .mute, keyCode: UInt32(kVK_F6)),
    HotKeyDefinition(id: 2, action: .camera, keyCode: UInt32(kVK_F7)),
    HotKeyDefinition(id: 3, action: .raiseHand, keyCode: UInt32(kVK_F8)),
  ]

  private var eventHandlerRef: EventHandlerRef?
  private var hotKeyRefs: [EventHotKeyRef] = []
  private var handler: ((MeetingAction) -> Void)?
  private var pressGates: [UInt32: TriggerPressGate] = [:]

  func registerDefaultActions(handler: @escaping (MeetingAction) -> Void) throws {
    unregister()
    self.handler = handler
    pressGates = Dictionary(
      uniqueKeysWithValues: Self.definitions.map { ($0.id, TriggerPressGate()) }
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
          let definition = GlobalHotKeyRegistrar.definitions.first(where: {
            $0.id == hotKeyID.id
          })
        else {
          return OSStatus(eventNotHandledErr)
        }

        let registrar = Unmanaged<GlobalHotKeyRegistrar>
          .fromOpaque(userData)
          .takeUnretainedValue()
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

    for definition in Self.definitions {
      var hotKeyRef: EventHotKeyRef?
      let hotKeyID = EventHotKeyID(signature: Self.signature, id: definition.id)
      let status = RegisterEventHotKey(
        definition.keyCode,
        0,
        hotKeyID,
        GetApplicationEventTarget(),
        0,
        &hotKeyRef
      )

      guard status == noErr, let hotKeyRef else {
        unregister()
        throw GlobalHotKeyError.registrationFailed(action: definition.action, status: status)
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
  }

  deinit {
    unregister()
  }
}
