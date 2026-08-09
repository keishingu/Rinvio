import AppKit
import Carbon
import QuickDrawCore

enum ShortcutCapture {
  static func keyStroke(from event: NSEvent) -> KeyStroke? {
    guard let key = keyDisplay(for: event) else { return nil }

    var modifiers = Set<ModifierKey>()
    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    if flags.contains(.control) { modifiers.insert(.control) }
    if flags.contains(.option) { modifiers.insert(.option) }
    if flags.contains(.command) { modifiers.insert(.command) }
    if flags.contains(.shift) { modifiers.insert(.shift) }

    let modifierDisplay = [
      modifiers.contains(.control) ? "⌃" : "",
      modifiers.contains(.option) ? "⌥" : "",
      modifiers.contains(.command) ? "⌘" : "",
      modifiers.contains(.shift) ? "⇧" : "",
    ].joined()

    return KeyStroke(
      virtualKeyCode: event.keyCode,
      modifiers: modifiers,
      displayValue: modifierDisplay + key
    )
  }

  private static func keyDisplay(for event: NSEvent) -> String? {
    switch Int(event.keyCode) {
    case kVK_F1: "F1"
    case kVK_F2: "F2"
    case kVK_F3: "F3"
    case kVK_F4: "F4"
    case kVK_F5: "F5"
    case kVK_F6: "F6"
    case kVK_F7: "F7"
    case kVK_F8: "F8"
    case kVK_F9: "F9"
    case kVK_F10: "F10"
    case kVK_F11: "F11"
    case kVK_F12: "F12"
    case kVK_F13: "F13"
    case kVK_F14: "F14"
    case kVK_F15: "F15"
    case kVK_F16: "F16"
    case kVK_F17: "F17"
    case kVK_F18: "F18"
    case kVK_F19: "F19"
    case kVK_F20: "F20"
    case kVK_Return: "↩"
    case kVK_Tab: "⇥"
    case kVK_Space: "Space"
    case kVK_Delete: "⌫"
    case kVK_ForwardDelete: "⌦"
    case kVK_LeftArrow: "←"
    case kVK_RightArrow: "→"
    case kVK_UpArrow: "↑"
    case kVK_DownArrow: "↓"
    case kVK_Home: "Home"
    case kVK_End: "End"
    case kVK_PageUp: "Page Up"
    case kVK_PageDown: "Page Down"
    default:
      event.charactersIgnoringModifiers?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .uppercased()
        .nilIfEmpty
    }
  }
}

extension String {
  fileprivate var nilIfEmpty: String? { isEmpty ? nil : self }
}
