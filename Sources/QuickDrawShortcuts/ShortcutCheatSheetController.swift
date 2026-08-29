import AppKit
import QuartzCore
import QuickDrawCore
import SwiftUI

private struct ShortcutCheatSheetEntry: Identifiable {
  let action: Action
  let name: String
  let quickDrawShortcut: String
  let applicationShortcut: String
  let systemImage: String

  var id: Action { action }
}

private struct ShortcutCheatSheetGroup: Identifiable {
  let domain: ActionDomain
  let title: String
  let entries: [ShortcutCheatSheetEntry]

  var id: ActionDomain { domain }
}

private struct ShortcutCheatSheetContent {
  let applicationName: String
  let applicationSystemImage: String
  let dismissalHint: String
  let groups: [ShortcutCheatSheetGroup]
}

@MainActor
final class ShortcutCheatSheetController {
  private static let holdDelay: TimeInterval = 0.6

  private let configurationStore: QuickDrawConfigurationStore
  private let foregroundProvider: any ForegroundApplicationProviding
  private let activeTabProvider: ChromeActiveTabProvider
  private let languageProvider: () -> AppLanguage
  private let panel: NSPanel

  private var currentModifiers = Set<ModifierKey>()
  private(set) var isAwaitingModifierRelease = false
  private var presentedModifiers: Set<ModifierKey>?
  private var pendingModifiers: Set<ModifierKey>?
  private var pendingPresentation: DispatchWorkItem?
  private var pendingPreviewDismissal: DispatchWorkItem?

  var isPreviewVisible: Bool {
    pendingPreviewDismissal != nil && panel.isVisible
  }

  var isCheatSheetEnabled = true {
    didSet {
      if !isCheatSheetEnabled { reset() }
    }
  }

  var isQuickDrawEnabled = true {
    didSet {
      if !isQuickDrawEnabled { reset() }
    }
  }

  var isSuppressed = false {
    didSet {
      if isSuppressed { reset() }
    }
  }

  init(
    configurationStore: QuickDrawConfigurationStore,
    foregroundProvider: any ForegroundApplicationProviding,
    activeTabProvider: ChromeActiveTabProvider,
    languageProvider: @escaping () -> AppLanguage
  ) {
    self.configurationStore = configurationStore
    self.foregroundProvider = foregroundProvider
    self.activeTabProvider = activeTabProvider
    self.languageProvider = languageProvider

    panel = NSPanel(
      contentRect: .zero,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = true
    panel.ignoresMouseEvents = true
    panel.hidesOnDeactivate = false
    panel.level = .statusBar
    panel.collectionBehavior = [
      .canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle,
    ]
    // Best effort only. Apple now documents this as a legacy value and capture apps may ignore it.
    panel.sharingType = .none
  }

  func handleModifierChange(_ modifiers: Set<ModifierKey>) {
    currentModifiers = modifiers

    if modifiers.isEmpty {
      isAwaitingModifierRelease = false
      if pendingPreviewDismissal == nil { reset() }
      return
    }
    guard !isAwaitingModifierRelease else {
      reset()
      return
    }
    guard isCheatSheetEnabled, isQuickDrawEnabled, !isSuppressed else {
      return
    }

    let hasMatchingTrigger =
      !configurationStore.actions(withTriggerModifiers: modifiers).isEmpty
    let hasMatchingApplicationShortcut = ActionTarget.allCases.contains { target in
      !configurationStore.actions(
        withApplicationShortcutModifiers: modifiers,
        for: target
      ).isEmpty
    }
    guard hasMatchingTrigger || hasMatchingApplicationShortcut else {
      reset()
      return
    }
    if panel.isVisible {
      guard presentedModifiers != modifiers else { return }
      pendingPresentation?.cancel()
      pendingPresentation = nil
      pendingModifiers = nil
      pendingPreviewDismissal?.cancel()
      pendingPreviewDismissal = nil
      if !presentForForegroundApplication(
        isPreview: false,
        triggerModifiers: modifiers
      ) {
        reset()
      }
      return
    }
    if pendingPresentation != nil {
      guard pendingModifiers != modifiers else { return }
      pendingPresentation?.cancel()
      pendingPresentation = nil
    }

    let activationModifiers = modifiers
    let workItem = DispatchWorkItem { [weak self] in
      guard let self else { return }
      self.pendingPresentation = nil
      self.pendingModifiers = nil
      guard self.currentModifiers == activationModifiers else { return }
      self.presentForForegroundApplication(
        isPreview: false,
        triggerModifiers: activationModifiers
      )
    }
    pendingModifiers = activationModifiers
    pendingPresentation = workItem
    DispatchQueue.main.asyncAfter(
      deadline: .now() + Self.holdDelay,
      execute: workItem
    )
  }

  func handleShortcutExecution() {
    isAwaitingModifierRelease = !currentModifiers.isEmpty
    reset()
  }

  func handleNonModifierKeyPress() {
    handleShortcutExecution()
  }

  func reset() {
    pendingPresentation?.cancel()
    pendingPresentation = nil
    pendingModifiers = nil
    pendingPreviewDismissal?.cancel()
    pendingPreviewDismissal = nil
    presentedModifiers = nil
    panel.orderOut(nil)
  }

  func presentPreview() {
    guard isQuickDrawEnabled, !isSuppressed else { return }
    presentForForegroundApplication(isPreview: true, triggerModifiers: nil)
    guard panel.isVisible else { return }

    let workItem = DispatchWorkItem { [weak self] in self?.reset() }
    pendingPreviewDismissal = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
  }

  @discardableResult
  private func presentForForegroundApplication(
    isPreview: Bool,
    triggerModifiers: Set<ModifierKey>?
  ) -> Bool {
    guard isQuickDrawEnabled, !isSuppressed else { return false }
    guard isPreview || isCheatSheetEnabled else { return false }
    guard isPreview || foregroundProvider.isPotentialQuickDrawTargetForeground() else {
      return false
    }
    guard
      let application = foregroundProvider.foregroundApplication(),
      let bundleIdentifier = application.bundleIdentifier,
      let foregroundTarget = ActionCatalog.target(forBundleIdentifier: bundleIdentifier)
    else {
      return false
    }

    let activeTabURL =
      foregroundTarget == .googleChrome
      ? try? activeTabProvider.activeTabURL()
      : nil
    let context = ForegroundContext(
      bundleIdentifier: bundleIdentifier,
      activeTabURL: activeTabURL
    )
    let router = ActionRouter(
      overrideProvider: configurationStore,
      applicationEnablementProvider: configurationStore
    )
    let copy = QuickDrawCopy(language: languageProvider())

    var routedTargets = Set<ActionTarget>()
    var routedEntries: [(domain: ActionDomain, entry: ShortcutCheatSheetEntry)] = []
    for definition in ActionDefinition.all {
      guard case .success(let route) = router.route(action: definition.action, context: context)
      else { continue }
      let trigger = configurationStore.trigger(for: definition.action)
      let matchesQuickDrawTrigger = trigger?.modifiers == triggerModifiers
      let matchesApplicationShortcut = route.shortcut.modifiers == triggerModifiers
      guard
        triggerModifiers == nil || matchesQuickDrawTrigger || matchesApplicationShortcut
      else { continue }
      routedTargets.insert(route.target)
      routedEntries.append(
        (
          domain: definition.domain,
          entry:
            ShortcutCheatSheetEntry(
              action: definition.action,
              name: copy.actionName(definition.action),
              quickDrawShortcut: trigger?.displayValue ?? "—",
              applicationShortcut: route.shortcut.displayValue,
              systemImage: definition.systemImage
            )
        )
      )
    }
    let entriesByDomain = Dictionary(grouping: routedEntries, by: \.domain)

    let groups = ActionDomain.allCases.compactMap { domain -> ShortcutCheatSheetGroup? in
      guard let pairs = entriesByDomain[domain], !pairs.isEmpty else { return nil }
      return ShortcutCheatSheetGroup(
        domain: domain,
        title: copy.actionDomainName(domain),
        entries: pairs.map(\.entry)
      )
    }
    guard !groups.isEmpty else { return false }

    let presentationTarget =
      routedTargets.first {
        ActionCatalog.application(for: $0).webApplication != nil
      } ?? foregroundTarget
    let applicationPresentation = ApplicationMapping.current().first {
      $0.target == presentationTarget
    }
    let content = ShortcutCheatSheetContent(
      applicationName: presentationTarget.displayName,
      applicationSystemImage: applicationPresentation?.systemImage ?? "app.fill",
      dismissalHint:
        isPreview
        ? copy.previewClosesAutomatically
        : copy.releaseModifiersToClose(modifierSymbols(triggerModifiers ?? [])),
      groups: groups
    )

    return present(content, triggerModifiers: triggerModifiers)
  }

  @discardableResult
  private func present(
    _ content: ShortcutCheatSheetContent,
    triggerModifiers: Set<ModifierKey>?
  ) -> Bool {
    let screen = screenContainingPointer() ?? NSScreen.main ?? NSScreen.screens.first
    guard let screen else { return false }
    let wasVisible = panel.isVisible

    let rowCount = content.groups.reduce(0) { $0 + $1.entries.count }
    let width = min(620.0, screen.visibleFrame.width - 48.0)
    let idealHeight = 117.0 + CGFloat(content.groups.count * 28) + CGFloat(rowCount * 35)
    let height = min(idealHeight, screen.visibleFrame.height * 0.72)
    let size = NSSize(width: width, height: height)

    let rootView = ShortcutCheatSheetView(content: content)
      .frame(width: size.width, height: size.height)
    panel.contentView = NSHostingView(rootView: rootView)
    panel.setContentSize(size)
    panel.setFrameOrigin(
      NSPoint(
        x: screen.visibleFrame.midX - size.width / 2,
        y: screen.visibleFrame.midY - size.height / 2
      )
    )
    presentedModifiers = triggerModifiers

    if wasVisible || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
      panel.alphaValue = 1
      panel.orderFrontRegardless()
    } else {
      panel.alphaValue = 0
      panel.orderFrontRegardless()
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.16
        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
        panel.animator().alphaValue = 1
      }
    }
    return true
  }

  private func screenContainingPointer() -> NSScreen? {
    let location = NSEvent.mouseLocation
    return NSScreen.screens.first { NSMouseInRect(location, $0.frame, false) }
  }

  private func modifierSymbols(_ modifiers: Set<ModifierKey>) -> String {
    [
      modifiers.contains(.command) ? "⌘" : "",
      modifiers.contains(.option) ? "⌥" : "",
      modifiers.contains(.control) ? "⌃" : "",
      modifiers.contains(.shift) ? "⇧" : "",
    ].joined()
  }
}

private struct ShortcutCheatSheetView: View {
  let content: ShortcutCheatSheetContent

  private let shortcutColumnWidth = 86.0

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 11) {
        Image(systemName: content.applicationSystemImage)
          .font(.title3)
          .symbolRenderingMode(.hierarchical)
          .frame(width: 32, height: 32)
          .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

        VStack(alignment: .leading, spacing: 2) {
          Text(content.applicationName)
            .font(.headline)
          Text(content.dismissalHint)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Divider()

      HStack(spacing: 10) {
        Spacer(minLength: 0)
        Text("Rinvio")
          .frame(width: shortcutColumnWidth, alignment: .center)
        Divider()
        Text(content.applicationName)
          .frame(width: shortcutColumnWidth, alignment: .center)
      }
      .font(.caption.weight(.semibold))
      .foregroundStyle(.secondary)
      .frame(height: 18)

      ScrollView {
        VStack(alignment: .leading, spacing: 13) {
          ForEach(content.groups) { group in
            VStack(alignment: .leading, spacing: 7) {
              Text(group.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

              VStack(alignment: .leading, spacing: 4) {
                ForEach(group.entries) { entry in
                  HStack(spacing: 10) {
                    Image(systemName: entry.systemImage)
                      .symbolRenderingMode(.hierarchical)
                      .foregroundStyle(.secondary)
                      .frame(width: 18)
                    Text(entry.name)
                      .lineLimit(1)
                      .minimumScaleFactor(0.82)
                    Spacer(minLength: 6)
                    ShortcutCheatSheetKeyBadge(text: entry.quickDrawShortcut)
                      .frame(width: shortcutColumnWidth)
                    Divider()
                    ShortcutCheatSheetKeyBadge(text: entry.applicationShortcut)
                      .frame(width: shortcutColumnWidth)
                  }
                  .frame(maxWidth: .infinity, minHeight: 31, alignment: .leading)
                  .accessibilityElement(children: .combine)
                }
              }
            }
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 17)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    .accessibilityElement(children: .contain)
  }
}

private struct ShortcutCheatSheetKeyBadge: View {
  let text: String

  var body: some View {
    Text(text)
      .font(.caption.monospaced().weight(.medium))
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
  }
}
