import AppKit
import SwiftUI

@MainActor
final class ConfigurationWindowController: NSWindowController, NSWindowDelegate {
  init(model: QuickDrawAppModel) {
    let content = QuickDrawRootView(model: model)
    let hostingController = NSHostingController(rootView: content)
    let window = NSWindow(contentViewController: hostingController)
    window.title = "Rinvio"
    window.setContentSize(NSSize(width: 1_160, height: 720))
    window.minSize = NSSize(width: 860, height: 560)
    window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
    window.titlebarAppearsTransparent = true
    window.isReleasedWhenClosed = false
    window.center()

    super.init(window: window)
    window.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func present() {
    showWindow(nil)
    window?.makeKeyAndOrderFront(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
  }
}
