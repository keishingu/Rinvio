import CoreGraphics
import Foundation
import QuickDrawCore

enum ShortcutExecutionError: LocalizedError {
  case postEventPermissionRequired
  case eventSourceUnavailable
  case eventCreationFailed

  var errorDescription: String? {
    switch self {
    case .postEventPermissionRequired:
      return "Accessibility permission is required to deliver shortcuts"
    case .eventSourceUnavailable:
      return "A keyboard event source could not be created"
    case .eventCreationFailed:
      return "The application shortcut event could not be created"
    }
  }
}

struct ShortcutExecutor: ShortcutDelivering {
  var hasPostEventAccess: Bool {
    CGPreflightPostEventAccess()
  }

  @discardableResult
  func requestPostEventAccess() -> Bool {
    CGRequestPostEventAccess()
  }

  func deliver(_ shortcut: KeyStroke) throws {
    guard hasPostEventAccess else {
      throw ShortcutExecutionError.postEventPermissionRequired
    }
    // Keep trigger modifiers (for example Control in Control+6) out of the
    // application shortcut emitted by QuickDraw.
    guard let source = CGEventSource(stateID: .privateState) else {
      throw ShortcutExecutionError.eventSourceUnavailable
    }
    let events = try ShortcutEventPlanner.plan(for: shortcut).map { plannedEvent in
      guard
        let event = CGEvent(
          keyboardEventSource: source,
          virtualKey: CGKeyCode(plannedEvent.virtualKeyCode),
          keyDown: plannedEvent.phase == .keyDown
        )
      else {
        throw ShortcutExecutionError.eventCreationFailed
      }
      event.flags = eventFlags(
        for: plannedEvent.modifiers,
        virtualKeyCode: plannedEvent.virtualKeyCode
      )
      event.setIntegerValueField(
        .eventSourceUserData,
        value: plannedEvent.sourceMarker
      )
      return event
    }
    for event in events {
      event.post(tap: .cgSessionEventTap)
    }
  }

  private func eventFlags(
    for modifiers: Set<ModifierKey>,
    virtualKeyCode: UInt16
  ) -> CGEventFlags {
    var flags: CGEventFlags = []
    if modifiers.contains(.command) {
      flags.insert(.maskCommand)
    }
    if modifiers.contains(.shift) {
      flags.insert(.maskShift)
    }
    if modifiers.contains(.control) {
      flags.insert(.maskControl)
    }
    if modifiers.contains(.option) {
      flags.insert(.maskAlternate)
    }
    // Match physical arrow-key events for Finder and application shortcuts.
    if [123, 124, 125, 126].contains(virtualKeyCode) {
      flags.insert(.maskNumericPad)
    }
    return flags
  }
}
