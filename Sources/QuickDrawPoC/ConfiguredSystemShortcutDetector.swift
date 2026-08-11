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
    .showDesktop: "36",
    .showNotificationCenter: "163",
    .toggleDoNotDisturb: "175",
    .toggleStageManager: "222",
    .fillWindow: "237",
    .tileWindowLeft: "240",
    .tileWindowRight: "241",
    .switchDesktop1: "118",
    .switchDesktop2: "119",
    .switchDesktop3: "120",
    .switchDesktop4: "121",
    .switchDesktop5: "122",
  ]

  private static let functionModifierActions: Set<Action> = [
    .fillWindow, .tileWindowLeft, .tileWindowRight,
  ]

  private static let fallbackShortcuts: [Action: KeyStroke] = [
    .fillWindow: KeyStroke(
      virtualKeyCode: 3,
      modifiers: [.control, .function],
      displayValue: "⌃🌐︎F"
    ),
    .tileWindowLeft: KeyStroke(
      virtualKeyCode: 123,
      modifiers: [.control, .function],
      displayValue: "⌃🌐︎←"
    ),
    .tileWindowRight: KeyStroke(
      virtualKeyCode: 124,
      modifiers: [.control, .function],
      displayValue: "⌃🌐︎→"
    ),
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

    var parsedShortcuts = entries.compactMap { rawShortcutID, rawEntry in
      let shortcutID = rawShortcutID as? String
      let includeFunction =
        shortcutID.map { identifier in
          functionModifierActions.contains { action in
            shortcutIDByAction[action] == identifier
          }
        } ?? false
      return parseEntry(rawEntry, includeFunction: includeFunction)
    }
    parsedShortcuts.append(
      contentsOf: fallbackShortcuts.compactMap { action, shortcut in
        guard let shortcutID = shortcutIDByAction[action], entries[shortcutID] == nil else {
          return nil
        }
        return shortcut
      }
    )
    let actionShortcuts: [Action: KeyStroke] = Dictionary(
      uniqueKeysWithValues: shortcutIDByAction.compactMap { action, shortcutID in
        if let rawEntry = entries[shortcutID] {
          guard
            let shortcut = parseEntry(
              rawEntry,
              includeFunction: functionModifierActions.contains(action)
            )
          else {
            return nil
          }
          return (action, shortcut)
        }
        return fallbackShortcuts[action].map { (action, $0) }
      }
    )
    return (Set(parsedShortcuts.map(ShortcutIdentity.init)), actionShortcuts)
  }

  private static func parseEntry(
    _ rawEntry: Any,
    includeFunction: Bool = false
  ) -> KeyStroke? {
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
    if includeFunction, rawFlags & CGEventFlags.maskSecondaryFn.rawValue != 0 {
      modifiers.insert(.function)
    }

    guard let keyDisplay = keyDisplay(for: keyCodeNumber.uint16Value) else { return nil }
    let modifierDisplay = [
      modifiers.contains(.control) ? "⌃" : "",
      modifiers.contains(.option) ? "⌥" : "",
      modifiers.contains(.shift) ? "⇧" : "",
      modifiers.contains(.command) ? "⌘" : "",
      modifiers.contains(.function) ? "🌐︎" : "",
    ].joined()

    return KeyStroke(
      virtualKeyCode: keyCodeNumber.uint16Value,
      modifiers: modifiers,
      displayValue: modifierDisplay + keyDisplay
    )
  }

  private static func keyDisplay(for virtualKeyCode: UInt16) -> String? {
    switch virtualKeyCode {
    case 1: "S"
    case 2: "D"
    case 3: "F"
    case 18: "1"
    case 19: "2"
    case 20: "3"
    case 21: "4"
    case 23: "5"
    case 45: "N"
    case 103: "F11"
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
