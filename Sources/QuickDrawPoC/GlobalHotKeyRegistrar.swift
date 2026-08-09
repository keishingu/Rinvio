import Carbon
import Foundation
import QuickDrawCore

enum GlobalHotKeyError: LocalizedError {
  case eventHandlerInstallationFailed(OSStatus)
  case registrationFailed(OSStatus)

  var errorDescription: String? {
    switch self {
    case .eventHandlerInstallationFailed(let status):
      return "Could not install the global hotkey handler (OSStatus \(status))"
    case .registrationFailed(let status):
      return "F6 could not be registered (OSStatus \(status))"
    }
  }
}

final class GlobalHotKeyRegistrar {
  private static let signature: OSType = 0x5144_5043  // QDPC
  private static let muteHotKeyID: UInt32 = 1

  private var eventHandlerRef: EventHandlerRef?
  private var hotKeyRef: EventHotKeyRef?
  private var handler: (() -> Void)?
  private var pressGate = TriggerPressGate()

  func registerF6(handler: @escaping () -> Void) throws {
    unregister()
    self.handler = handler

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
          hotKeyID.id == GlobalHotKeyRegistrar.muteHotKeyID
        else {
          return OSStatus(eventNotHandledErr)
        }

        let registrar = Unmanaged<GlobalHotKeyRegistrar>
          .fromOpaque(userData)
          .takeUnretainedValue()
        switch GetEventKind(event) {
        case UInt32(kEventHotKeyPressed):
          if registrar.pressGate.shouldInvoke(for: .pressed) {
            registrar.handler?()
          }
        case UInt32(kEventHotKeyReleased):
          _ = registrar.pressGate.shouldInvoke(for: .released)
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

    let hotKeyID = EventHotKeyID(
      signature: Self.signature,
      id: Self.muteHotKeyID
    )
    let registrationStatus = RegisterEventHotKey(
      UInt32(kVK_F6),
      0,
      hotKeyID,
      GetApplicationEventTarget(),
      0,
      &hotKeyRef
    )

    guard registrationStatus == noErr else {
      unregister()
      throw GlobalHotKeyError.registrationFailed(registrationStatus)
    }
  }

  func unregister() {
    if let hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
    }
    if let eventHandlerRef {
      RemoveEventHandler(eventHandlerRef)
    }
    hotKeyRef = nil
    eventHandlerRef = nil
    handler = nil
    pressGate = TriggerPressGate()
  }

  deinit {
    unregister()
  }
}
