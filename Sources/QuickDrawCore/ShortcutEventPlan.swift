public enum KeyEventPhase: String, Equatable, Sendable {
  case keyDown
  case keyUp
}

public struct PlannedKeyEvent: Equatable, Sendable {
  public let phase: KeyEventPhase
  public let virtualKeyCode: UInt16
  public let modifiers: Set<ModifierKey>
  public let sourceMarker: Int64

  public init(
    phase: KeyEventPhase,
    virtualKeyCode: UInt16,
    modifiers: Set<ModifierKey>,
    sourceMarker: Int64
  ) {
    self.phase = phase
    self.virtualKeyCode = virtualKeyCode
    self.modifiers = modifiers
    self.sourceMarker = sourceMarker
  }
}

public enum ShortcutEventPlanner {
  public static let quickDrawSourceMarker: Int64 = 0x5144_5043  // QDPC

  public static func plan(for shortcut: KeyStroke) -> [PlannedKeyEvent] {
    [
      PlannedKeyEvent(
        phase: .keyDown,
        virtualKeyCode: shortcut.virtualKeyCode,
        modifiers: shortcut.modifiers,
        sourceMarker: quickDrawSourceMarker
      ),
      PlannedKeyEvent(
        phase: .keyUp,
        virtualKeyCode: shortcut.virtualKeyCode,
        modifiers: shortcut.modifiers,
        sourceMarker: quickDrawSourceMarker
      ),
    ]
  }
}
