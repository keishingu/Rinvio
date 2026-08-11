import CoreFoundation
import CoreGraphics
import Foundation
import QuickDrawCore

final class ConfiguredSystemShortcutDetector {
  private var shortcuts: Set<ShortcutIdentity> = []
  private var actionShortcuts: [Action: KeyStroke] = [:]

  private static let shortcutIDByAction: [Action: String] = [
    .missionControl: "32",
    .applicationExpose: "33",
    .previousDesktop: "79",
    .nextDesktop: "81",
  ]

  init() {
    refresh()
  }

  func refresh() {
    let loaded = Self.loadConfiguredShortcuts()
    shortcuts = loaded.shortcuts
    actionShortcuts = loaded.actionShortcuts
  }

  func conflicts(with shortcut: KeyStroke) -> Bool {
    shortcuts.contains(ShortcutIdentity(shortcut))
  }

  func shortcut(for action: Action) -> KeyStroke? {
    actionShortcuts[action]
  }

  private static func loadConfiguredShortcuts() -> (
    shortcuts: Set<ShortcutIdentity>, actionShortcuts: [Action: KeyStroke]
  ) {
    guard
      let propertyList = CFPreferencesCopyValue(
        "AppleSymbolicHotKeys" as CFString,
        "com.apple.symbolichotkeys" as CFString,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
      ),
      let entries = propertyList as? NSDictionary
    else {
      return ([], [:])
    }

    let parsedShortcuts = entries.allValues.compactMap(parseEntry)
    let actionShortcuts: [Action: KeyStroke] = Dictionary(
      uniqueKeysWithValues: shortcutIDByAction.compactMap { action, shortcutID in
        guard let rawEntry = entries[shortcutID], let shortcut = parseEntry(rawEntry) else {
          return nil
        }
        return (action, shortcut)
      }
    )
    return (Set(parsedShortcuts.map(ShortcutIdentity.init)), actionShortcuts)
  }

  private static func parseEntry(_ rawEntry: Any) -> KeyStroke? {
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

    guard let keyDisplay = keyDisplay(for: keyCodeNumber.uint16Value) else { return nil }
    let modifierDisplay = [
      modifiers.contains(.command) ? "⌘" : "",
      modifiers.contains(.option) ? "⌥" : "",
      modifiers.contains(.control) ? "⌃" : "",
      modifiers.contains(.shift) ? "⇧" : "",
    ].joined()

    return KeyStroke(
      virtualKeyCode: keyCodeNumber.uint16Value,
      modifiers: modifiers,
      displayValue: modifierDisplay + keyDisplay
    )
  }

  private static func keyDisplay(for virtualKeyCode: UInt16) -> String? {
    switch virtualKeyCode {
    case 123: "←"
    case 124: "→"
    case 125: "↓"
    case 126: "↑"
    default: nil
    }
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
