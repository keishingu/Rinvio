public enum TriggerKeyPhase: Equatable, Sendable {
  case pressed
  case released
}

public struct TriggerPressGate: Sendable {
  private var isPressed = false

  public init() {}

  public mutating func shouldInvoke(for phase: TriggerKeyPhase) -> Bool {
    switch phase {
    case .pressed:
      guard !isPressed else {
        return false
      }
      isPressed = true
      return true

    case .released:
      isPressed = false
      return false
    }
  }
}
