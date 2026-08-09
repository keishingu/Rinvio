public enum KnownSystemShortcut: String, Equatable, Sendable {
  case copyStyle
  case showOrHideDock
  case focusSearchField
  case hideOtherApplications
  case showInspector
  case openDownloads
  case minimizeAllWindows
  case showOrHideToolbar
  case closeAllWindows
  case forceQuit
  case finderSearch
  case toggleZoom
}

public enum TriggerConflict: Equatable, Sendable {
  case knownSystemShortcut(KnownSystemShortcut)
  case configuredSystemShortcut
}

public enum SystemShortcutCatalog {
  public static func knownConflict(for shortcut: KeyStroke) -> KnownSystemShortcut? {
    guard shortcut.modifiers == [.command, .option] else { return nil }

    return switch shortcut.virtualKeyCode {
    case 8: .copyStyle
    case 2: .showOrHideDock
    case 3: .focusSearchField
    case 4: .hideOtherApplications
    case 34: .showInspector
    case 37: .openDownloads
    case 46: .minimizeAllWindows
    case 17: .showOrHideToolbar
    case 13: .closeAllWindows
    case 53: .forceQuit
    case 49: .finderSearch
    case 28: .toggleZoom
    default: nil
    }
  }
}
