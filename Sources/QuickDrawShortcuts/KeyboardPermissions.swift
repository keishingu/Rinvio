import CoreGraphics

struct KeyboardPermissionState: Equatable {
  let hasInputMonitoringAccess: Bool
  let hasPostEventAccess: Bool

  var canMonitorTriggers: Bool { hasInputMonitoringAccess }
  var canDeliverShortcuts: Bool { hasPostEventAccess }
  var isFullyAuthorized: Bool { canMonitorTriggers && canDeliverShortcuts }
}

struct InputMonitoringAuthorizer {
  private let preflight: () -> Bool
  private let request: () -> Bool

  init(
    preflight: @escaping () -> Bool = { CGPreflightListenEventAccess() },
    request: @escaping () -> Bool = { CGRequestListenEventAccess() }
  ) {
    self.preflight = preflight
    self.request = request
  }

  var hasAccess: Bool { preflight() }

  @discardableResult
  func requestAccess() -> Bool {
    request()
  }
}
