import CoreFoundation
import CoreGraphics
import Foundation
import QuickDrawCore

final class ConfiguredSystemShortcutDetector {
  private var shortcuts: Set<ShortcutIdentity> = []

  init() {
    refresh()
  }

  func refresh() {
    shortcuts = Self.loadConfiguredShortcuts()
  }

  func conflicts(with shortcut: KeyStroke) -> Bool {
    shortcuts.contains(ShortcutIdentity(shortcut))
  }

  private static func loadConfiguredShortcuts() -> Set<ShortcutIdentity> {
    guard
      let propertyList = CFPreferencesCopyValue(
        "AppleSymbolicHotKeys" as CFString,
        "com.apple.symbolichotkeys" as CFString,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
      ),
      let entries = propertyList as? NSDictionary
    else {
      return []
    }

    return Set(entries.allValues.compactMap(parseEntry))
  }

  private static func parseEntry(_ rawEntry: Any) -> ShortcutIdentity? {
    guard
      let entry = rawEntry as? NSDictionary,
      (entry["enabled"] as? NSNumber)?.boolValue == true,
      let value = entry["value"] as? NSDictionary,
      value["type"] as? String == "standard",
      let parameters = value["parameters"] as? NSArray,
      parameters.count >= 3,
      let keyCodeNumber = parameters[1] as? NSNumber,
      let flagsNumber = parameters[2] as? NSNumber
    else {
      return nil
    }

    let rawFlags = flagsNumber.uint64Value
    var modifiers = Set<ModifierKey>()
    if rawFlags & CGEventFlags.maskCommand.rawValue != 0 { modifiers.insert(.command) }
    if rawFlags & CGEventFlags.maskAlternate.rawValue != 0 { modifiers.insert(.option) }
    if rawFlags & CGEventFlags.maskControl.rawValue != 0 { modifiers.insert(.control) }
    if rawFlags & CGEventFlags.maskShift.rawValue != 0 { modifiers.insert(.shift) }

    return ShortcutIdentity(
      virtualKeyCode: keyCodeNumber.uint16Value,
      modifiers: modifiers
    )
  }
}

private struct ShortcutIdentity: Hashable {
  let virtualKeyCode: UInt16
  let modifiers: Set<ModifierKey>

  init(virtualKeyCode: UInt16, modifiers: Set<ModifierKey>) {
    self.virtualKeyCode = virtualKeyCode
    self.modifiers = modifiers
  }

  init(_ shortcut: KeyStroke) {
    self.init(
      virtualKeyCode: shortcut.virtualKeyCode,
      modifiers: shortcut.modifiers
    )
  }
}
