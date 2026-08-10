import CoreGraphics
import Foundation
import QuickDrawCore

enum GlobalHotKeyError: LocalizedError {
  case eventTapCreationFailed
  case runLoopSourceCreationFailed

  var errorDescription: String? {
    switch self {
    case .eventTapCreationFailed:
      "Could not monitor shortcuts. Accessibility or Input Monitoring permission may be required."
    case .runLoopSourceCreationFailed:
      "Could not attach the shortcut monitor to the application run loop."
    }
  }
}

final class GlobalHotKeyRegistrar {
  private struct ShortcutIdentity: Hashable {
    let virtualKeyCode: UInt16
    let modifiers: Set<ModifierKey>

    init(_ shortcut: KeyStroke) {
      virtualKeyCode = shortcut.virtualKeyCode
      modifiers = shortcut.modifiers
    }
  }

  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var handler: (([Action]) -> Bool)?
  private var modifierHandler: ((Set<ModifierKey>) -> Void)?
  private var actionsByShortcut: [ShortcutIdentity: [Action]] = [:]
  private var consumedKeyCodes: Set<UInt16> = []

  func register(
    bindings: [Action: KeyStroke],
    handler: @escaping ([Action]) -> Bool,
    modifierHandler: @escaping (Set<ModifierKey>) -> Void
  ) throws {
    unregister()
    self.handler = handler
    self.modifierHandler = modifierHandler
    let actionOrder = Dictionary(
      uniqueKeysWithValues: Action.allCases.enumerated().map { ($0.element, $0.offset) }
    )
    let groupedBindings = Dictionary(grouping: bindings) { binding in
      ShortcutIdentity(binding.value)
    }
    actionsByShortcut = groupedBindings.mapValues { bindings in
      let actions = bindings.map(\.key)
      return actions.sorted { actionOrder[$0, default: 0] < actionOrder[$1, default: 0] }
    }

    let eventMask =
      (CGEventMask(1) << CGEventType.keyDown.rawValue)
      | (CGEventMask(1) << CGEventType.keyUp.rawValue)
      | (CGEventMask(1) << CGEventType.flagsChanged.rawValue)

    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: eventMask,
        callback: { _, eventType, event, userInfo in
          guard let userInfo else {
            return Unmanaged.passUnretained(event)
          }
          let registrar = Unmanaged<GlobalHotKeyRegistrar>
            .fromOpaque(userInfo)
            .takeUnretainedValue()
          return registrar.handle(eventType: eventType, event: event)
        },
        userInfo: Unmanaged.passUnretained(self).toOpaque()
      )
    else {
      unregister()
      throw GlobalHotKeyError.eventTapCreationFailed
    }

    guard let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) else {
      CFMachPortInvalidate(eventTap)
      unregister()
      throw GlobalHotKeyError.runLoopSourceCreationFailed
    }

    self.eventTap = eventTap
    self.runLoopSource = runLoopSource
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
  }

  func unregister() {
    if let runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
      CFRunLoopSourceInvalidate(runLoopSource)
    }
    if let eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
      CFMachPortInvalidate(eventTap)
    }
    runLoopSource = nil
    eventTap = nil
    handler = nil
    modifierHandler?([])
    modifierHandler = nil
    actionsByShortcut = [:]
    consumedKeyCodes = []
  }

  private func handle(eventType: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
    if eventType == .tapDisabledByTimeout || eventType == .tapDisabledByUserInput {
      if let eventTap {
        CGEvent.tapEnable(tap: eventTap, enable: true)
      }
      return Unmanaged.passUnretained(event)
    }

    if event.getIntegerValueField(.eventSourceUserData)
      == ShortcutEventPlanner.quickDrawSourceMarker
    {
      return Unmanaged.passUnretained(event)
    }

    if eventType == .flagsChanged {
      modifierHandler?(modifiers(from: event.flags))
      return Unmanaged.passUnretained(event)
    }

    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    if eventType == .keyUp {
      if consumedKeyCodes.remove(keyCode) != nil {
        return nil
      }
      return Unmanaged.passUnretained(event)
    }

    guard eventType == .keyDown else {
      return Unmanaged.passUnretained(event)
    }

    let shortcut = ShortcutIdentity(
      KeyStroke(
        virtualKeyCode: keyCode,
        modifiers: modifiers(from: event.flags),
        displayValue: ""
      )
    )
    guard let actions = actionsByShortcut[shortcut] else {
      return Unmanaged.passUnretained(event)
    }

    if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
      return consumedKeyCodes.contains(keyCode) ? nil : Unmanaged.passUnretained(event)
    }

    guard handler?(actions) == true else {
      return Unmanaged.passUnretained(event)
    }

    consumedKeyCodes.insert(keyCode)
    return nil
  }

  private func modifiers(from flags: CGEventFlags) -> Set<ModifierKey> {
    var modifiers = Set<ModifierKey>()
    if flags.contains(.maskCommand) { modifiers.insert(.command) }
    if flags.contains(.maskAlternate) { modifiers.insert(.option) }
    if flags.contains(.maskControl) { modifiers.insert(.control) }
    if flags.contains(.maskShift) { modifiers.insert(.shift) }
    return modifiers
  }

  deinit {
    unregister()
  }
}
