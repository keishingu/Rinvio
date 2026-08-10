import AppKit
import QuickDrawCore
import SwiftUI

struct QuickDrawRootView: View {
  @ObservedObject var model: QuickDrawAppModel

  @State private var selectedSection: QuickDrawSection? = .meeting
  @State private var selectedActionID: String? = Action.mute.rawValue
  @State private var selectedApplicationID: String? = "meeting:microsoftTeams"
  @State private var isInspectorPresented = true

  var body: some View {
    NavigationSplitView {
      sidebar
    } detail: {
      detail
    }
    .inspector(isPresented: $isInspectorPresented) {
      inspector
        .inspectorColumnWidth(min: 300, ideal: 340, max: 390)
    }
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        languageMenu
        enabledToggle

        Button {
          isInspectorPresented.toggle()
        } label: {
          Label(model.copy.inspector, systemImage: "sidebar.trailing")
        }
        .help(isInspectorPresented ? model.copy.hideInspector : model.copy.showInspector)
      }
    }
    .frame(minWidth: 860, minHeight: 560)
    .onAppear {
      model.refreshEnvironment()
      normalizeActionSelection(for: selectedSection ?? .meeting)
    }
    .onChange(of: selectedSection) { _, section in
      normalizeActionSelection(for: section ?? .meeting)
    }
  }

  private var selectedAction: ActionDefinition? {
    guard let domain = (selectedSection ?? .meeting).actionDomain else { return nil }
    return model.actions(in: domain).first { $0.id == selectedActionID }
      ?? model.actions(in: domain).first
  }

  private var languageMenu: some View {
    Menu {
      Picker(
        model.copy.languageLabel,
        selection: Binding(
          get: { model.language },
          set: model.setLanguage
        )
      ) {
        ForEach(AppLanguage.allCases) { language in
          Text(language.displayName)
            .tag(language)
        }
      }
    } label: {
      Label(model.copy.languageLabel, systemImage: "globe")
    }
    .help(model.copy.chooseLanguage)
  }

  private var enabledToggle: some View {
    HStack(spacing: 7) {
      Text(model.isEnabled ? model.copy.enabled : model.copy.paused)
        .foregroundStyle(.secondary)
      Toggle(
        "QuickDraw",
        isOn: Binding(
          get: { model.isEnabled },
          set: model.setEnabled
        )
      )
      .labelsHidden()
      .toggleStyle(.switch)
    }
    .help(model.isEnabled ? model.copy.pauseQuickDraw : model.copy.enableQuickDraw)
  }

  private var sidebar: some View {
    List(selection: $selectedSection) {
      Section(model.copy.actions) {
        ForEach(QuickDrawSection.actionSections) { section in
          Label(model.copy.sectionTitle(section), systemImage: section.systemImage)
            .tag(section)
        }
      }

      Section {
        ForEach(QuickDrawSection.utilitySections) { section in
          Label(model.copy.sectionTitle(section), systemImage: section.systemImage)
            .tag(section)
        }
      }
    }
    .navigationTitle("QuickDraw")
    .navigationSplitViewColumnWidth(min: 170, ideal: 200, max: 240)
    .safeAreaInset(edge: .bottom) {
      VStack(alignment: .leading, spacing: 5) {
        Label(
          model.isEnabled ? model.copy.quickDrawEnabled : model.copy.quickDrawPaused,
          systemImage: model.isEnabled ? "checkmark.circle.fill" : "pause.circle"
        )
        .font(.caption)
        .foregroundStyle(.secondary)

        Text(model.triggerSummary)
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
    }
  }

  @ViewBuilder
  private var detail: some View {
    switch selectedSection ?? .meeting {
    case .meeting, .chat, .development, .browser:
      if let domain = (selectedSection ?? .meeting).actionDomain {
        ActionsView(domain: domain, selection: $selectedActionID, model: model)
      }
    case .applications:
      ApplicationsView(selection: $selectedApplicationID, model: model)
    case .settings:
      SettingsView(model: model)
    case .diagnostics:
      DiagnosticsView(model: model)
    }
  }

  @ViewBuilder
  private var inspector: some View {
    switch selectedSection ?? .meeting {
    case .meeting, .chat, .development, .browser:
      if let selectedAction {
        ActionInspector(definition: selectedAction, model: model)
      } else {
        ContentUnavailableView(
          model.copy.noActionsInCategory,
          systemImage: (selectedSection ?? .meeting).systemImage
        )
      }
    case .applications:
      if let application = model.applications.first(where: {
        $0.id == selectedApplicationID?.split(separator: ":").last.map(String.init)
      })
        ?? model.applications.first
      {
        ApplicationInspector(
          application: application,
          model: model
        )
      } else {
        ContentUnavailableView(model.copy.noApplications, systemImage: "square.grid.2x2")
      }
    case .settings:
      SettingsInspector(model: model)
    case .diagnostics:
      DiagnosticsInspector(model: model)
    }
  }

  private func normalizeActionSelection(for section: QuickDrawSection) {
    guard let domain = section.actionDomain else { return }
    let definitions = model.actions(in: domain)
    guard !definitions.contains(where: { $0.id == selectedActionID }) else { return }
    selectedActionID = definitions.first?.id
  }
}

private struct SettingsView: View {
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    VStack(spacing: 0) {
      ContentHeader(
        title: model.copy.settings,
        subtitle: model.copy.shortcutGuideDescription
      )
      Divider()

      Form {
        Section(model.copy.shortcutGuide) {
          Toggle(
            model.copy.showShortcutGuideOnHold,
            isOn: Binding(
              get: { model.isCheatSheetEnabled },
              set: model.setCheatSheetEnabled
            )
          )
          Text(model.copy.shortcutGuideDescription)
            .font(.caption)
            .foregroundStyle(.secondary)
          Button(model.copy.previewShortcutGuide) {
            model.previewCheatSheet()
          }
        }

        Section(model.copy.screenSharingPrivacy) {
          Label(model.copy.screenSharingBestEffort, systemImage: "eye.slash")
          Text(model.copy.screenSharingLimitation)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .formStyle(.grouped)
    }
    .navigationTitle("QuickDraw")
  }
}

private struct ActionsView: View {
  let domain: ActionDomain
  @Binding var selection: String?
  @ObservedObject var model: QuickDrawAppModel

  private var definitions: [ActionDefinition] {
    model.actions(in: domain)
  }

  private var categories: [ActionCategory] {
    ActionCategory.allCases.filter { category in
      definitions.contains { $0.category == category }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      ContentHeader(
        title: model.copy.actionDomainName(domain),
        subtitle: model.copy.actionDomainSubtitle(domain)
      )
      Divider()

      List(selection: $selection) {
        ForEach(categories) { category in
          Section(model.copy.actionCategoryName(category)) {
            ForEach(definitions.filter { $0.category == category }) { definition in
              ActionRow(definition: definition, model: model)
                .tag(definition.id)
            }
          }
        }
      }
      .listStyle(.inset)
    }
    .navigationTitle("QuickDraw")
  }
}

private struct ActionRow: View {
  let definition: ActionDefinition
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 14) {
        Image(systemName: definition.systemImage)
          .font(.title2)
          .symbolRenderingMode(.hierarchical)
          .frame(width: 38, height: 38)
          .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 8) {
            Text(model.copy.actionName(definition.action))
              .font(.headline)
            if let trigger = model.trigger(for: definition.action) {
              KeyBadge(
                text: trigger.displayValue,
                accessibilityLabel:
                  "\(model.copy.shortcutAccessibilityPrefix) \(trigger.displayValue)"
              )
              if !model.triggerConflicts(for: definition.action).isEmpty {
                Image(systemName: "exclamationmark.triangle.fill")
                  .font(.caption)
                  .foregroundStyle(.orange)
                  .help(
                    model.copy.triggerConflictDescription(
                      model.triggerConflicts(for: definition.action)
                    )
                  )
                  .accessibilityLabel(model.copy.shortcutConflict)
              }
            } else {
              Text(model.copy.unassigned)
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
          }
          Text(model.copy.actionDescription(definition.action))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 8)
      }

      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 88), spacing: 14)],
        alignment: .leading,
        spacing: 7
      ) {
        ForEach(model.applications(in: definition.domain)) { application in
          CompactMapping(application: application, action: definition.action, model: model)
        }
      }
      .padding(.leading, 52)
    }
    .padding(.vertical, 9)
    .contentShape(Rectangle())
  }
}

private struct CompactMapping: View {
  let application: ApplicationMapping
  let action: Action
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    HStack(spacing: 7) {
      Image(systemName: application.systemImage)
        .frame(width: 18)
        .foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 1) {
        Text(application.compactName)
          .font(.caption)
          .lineLimit(1)
        Text(model.shortcut(for: action, target: application.target)?.displayValue ?? "—")
          .font(.caption2.monospaced())
          .foregroundStyle(
            model.shortcut(for: action, target: application.target) == nil
              ? .tertiary : .secondary
          )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct ApplicationsView: View {
  @Binding var selection: String?
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    VStack(spacing: 0) {
      ContentHeader(title: model.copy.applications, subtitle: model.copy.applicationsSubtitle)
      Divider()

      List(selection: $selection) {
        ForEach(ActionDomain.allCases) { domain in
          Section(model.copy.actionDomainName(domain)) {
            ForEach(model.applications(in: domain)) { application in
              HStack(spacing: 13) {
                Image(systemName: application.systemImage)
                  .font(.title3)
                  .symbolRenderingMode(.hierarchical)
                  .frame(width: 36, height: 36)
                  .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                  Text(application.name)
                    .font(.headline)
                  Text(application.identity)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                  Text(model.copy.actionCount(model.supportedActionCount(for: application.target)))
                  Text(application.isInstalled ? model.copy.detected : model.copy.notInstalled)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
              .padding(.vertical, 7)
              .tag("(domain.rawValue):(application.id)")
            }
          }
        }
      }
      .listStyle(.inset)
    }
    .navigationTitle("QuickDraw")
  }
}

private struct DiagnosticsView: View {
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    VStack(spacing: 0) {
      ContentHeader(title: model.copy.diagnostics, subtitle: model.copy.diagnosticsSubtitle)
      Divider()

      Form {
        Section(model.copy.currentStatus) {
          LabeledContent(model.copy.state, value: model.localizedStatus.headline)
          LabeledContent(model.copy.target, value: model.localizedStatus.target)
          LabeledContent(model.copy.result, value: model.localizedStatus.detail)
          LabeledContent(
            model.copy.globalShortcut,
            value: model.areHotKeysRegistered
              ? model.copy.hotKeysRegistered(model.registeredTriggerSummary)
              : model.copy.unavailable
          )
        }

        Section(model.copy.recentRoutingLog) {
          Text(model.diagnostics)
            .font(.caption.monospaced())
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)

          HStack {
            Button(model.copy.refresh) { model.refreshDiagnostics() }
            Button(model.copy.copyDiagnostics) { copyToPasteboard(model.diagnostics) }
          }
        }
      }
      .formStyle(.grouped)
    }
    .navigationTitle("QuickDraw")
  }
}

private struct ActionInspector: View {
  let definition: ActionDefinition
  @ObservedObject var model: QuickDrawAppModel
  @State private var isResetConfirmationPresented = false

  private var triggerConflicts: [TriggerConflict] {
    model.triggerConflicts(for: definition.action)
  }

  var body: some View {
    Form {
      Section {
        HStack(spacing: 12) {
          Image(systemName: definition.systemImage)
            .font(.title)
            .symbolRenderingMode(.hierarchical)
            .frame(width: 46, height: 46)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
          VStack(alignment: .leading, spacing: 3) {
            Text(model.copy.actionName(definition.action))
              .font(.title3.weight(.semibold))
            Text(model.copy.actionCategoryName(definition.category))
              .foregroundStyle(.secondary)
          }
        }
      }

      Section(model.copy.trigger) {
        LabeledContent(model.copy.globalShortcut) {
          HStack(spacing: 7) {
            if model.isTriggerOverridden(for: definition.action) {
              Text(model.copy.modified)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            if let trigger = model.trigger(for: definition.action) {
              KeyBadge(
                text: trigger.displayValue,
                accessibilityLabel:
                  "\(model.copy.shortcutAccessibilityPrefix) \(trigger.displayValue)"
              )
              if !triggerConflicts.isEmpty {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundStyle(.orange)
                  .accessibilityLabel(model.copy.shortcutConflict)
              }
            } else {
              Text(model.copy.unassigned)
                .foregroundStyle(.secondary)
            }
          }
        }

        if model.recordingDestination == .trigger(definition.action) {
          ShortcutRecordingRow(model: model)
        } else {
          HStack {
            Button(model.copy.changeShortcut) {
              model.beginRecording(.trigger(definition.action))
            }
            if model.isTriggerOverridden(for: definition.action) {
              Button(model.copy.restoreDefault) {
                model.resetTrigger(for: definition.action)
              }
            }
          }
        }
        Text(model.copy.triggerEditingDescription)
          .font(.caption)
          .foregroundStyle(.secondary)

        if !triggerConflicts.isEmpty {
          Label(model.copy.shortcutConflict, systemImage: "exclamationmark.triangle.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
          Text(model.copy.triggerConflictDescription(triggerConflicts))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      if let shortcutEditingError = model.shortcutEditingError {
        Section {
          Label(
            model.copy.localizedShortcutError(shortcutEditingError),
            systemImage: "exclamationmark.triangle"
          )
          .foregroundStyle(.red)
        }
      }

      Section(model.copy.applicationMappings) {
        ForEach(model.applications(in: definition.domain)) { application in
          MappingRow(
            application: application,
            action: definition.action,
            model: model
          )
        }
      }

      if model.hasOverrides(for: definition.action) {
        Section {
          Button(model.copy.restoreActionDefaults) {
            isResetConfirmationPresented = true
          }
        }
      }

      Section(model.copy.execution) {
        Toggle(
          model.copy.dryRun,
          isOn: Binding(
            get: { model.isDryRunEnabled },
            set: model.setDryRunEnabled
          )
        )
        Text(model.copy.dryRunDescription)
          .font(.caption)
          .foregroundStyle(.secondary)

        Button(model.copy.testLastActiveApplication) {
          model.runDryCheck(action: definition.action)
        }
        .disabled(!model.isEnabled)
      }

      PermissionSection(model: model)
    }
    .formStyle(.grouped)
    .confirmationDialog(
      model.copy.restoreActionTitle,
      isPresented: $isResetConfirmationPresented
    ) {
      Button(model.copy.restoreDefault) {
        model.resetAction(definition.action)
      }
      Button(model.copy.cancel, role: .cancel) {}
    } message: {
      Text(model.copy.restoreActionMessage)
    }
    .onDisappear {
      if model.recordingDestination != nil {
        model.cancelRecording()
      }
    }
  }
}

private struct MappingRow: View {
  let application: ApplicationMapping
  let action: Action
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 10) {
        Image(systemName: application.systemImage)
          .frame(width: 22)
          .foregroundStyle(.secondary)
        VStack(alignment: .leading, spacing: 2) {
          Text(application.name)
          Text(model.copy.executionDetail(for: application))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        if model.isShortcutOverridden(for: action, target: application.target) {
          Text(model.copy.modified)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        if let shortcut = model.shortcut(for: action, target: application.target) {
          KeyBadge(text: shortcut.displayValue)
        } else {
          Label(model.copy.noShortcut, systemImage: "minus.circle")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }

      if model.recordingDestination == .application(action, application.target) {
        ShortcutRecordingRow(model: model)
      } else {
        HStack {
          Button(model.copy.changeShortcut) {
            model.beginRecording(.application(action, application.target))
          }
          .buttonStyle(.link)

          if model.isShortcutOverridden(for: action, target: application.target) {
            Button(model.copy.restoreDefault) {
              model.resetShortcut(for: action, target: application.target)
            }
            .buttonStyle(.link)
          }
        }
      }
    }
  }
}

private struct ShortcutRecordingRow: View {
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    HStack {
      Label(model.copy.pressShortcut, systemImage: "keyboard")
        .foregroundStyle(.secondary)
      Spacer()
      Button(model.copy.cancel) { model.cancelRecording() }
    }
  }
}

private struct ApplicationInspector: View {
  let application: ApplicationMapping
  @ObservedObject var model: QuickDrawAppModel

  private var definitions: [ActionDefinition] {
    application.domains.flatMap(model.actions(in:))
  }

  private var categories: [ActionCategory] {
    ActionCategory.allCases.filter { category in
      definitions.contains { $0.category == category }
    }
  }

  var body: some View {
    Form {
      Section {
        HStack(spacing: 12) {
          Image(systemName: application.systemImage)
            .font(.title)
            .symbolRenderingMode(.hierarchical)
            .frame(width: 46, height: 46)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
          VStack(alignment: .leading, spacing: 3) {
            Text(application.name)
              .font(.title3.weight(.semibold))
            Text(application.isInstalled ? model.copy.detected : model.copy.notInstalled)
              .foregroundStyle(.secondary)
          }
        }
      }

      Section(model.copy.identity) {
        Text(application.identity)
          .textSelection(.enabled)
      }

      ForEach(categories) { category in
        Section(model.copy.actionCategoryName(category)) {
          ForEach(definitions.filter { $0.category == category }) { definition in
            HStack {
              Label(
                model.copy.actionName(definition.action),
                systemImage: definition.systemImage
              )
              Spacer()
              if model.isShortcutOverridden(
                for: definition.action,
                target: application.target
              ) {
                Text(model.copy.modified)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              if let shortcut = model.shortcut(
                for: definition.action,
                target: application.target
              ) {
                KeyBadge(text: shortcut.displayValue)
              } else {
                Text(model.copy.noShortcut)
                  .font(.caption)
                  .foregroundStyle(.tertiary)
              }
            }
          }
        }
      }

      Section(model.copy.method) {
        LabeledContent(
          model.copy.capability,
          value: model.copy.shortcutCapability(
            model.supportedActionCount(for: application.target),
            total: definitions.count
          )
        )
        Text(model.copy.executionDetail(for: application))
          .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }
}

private struct DiagnosticsInspector: View {
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    Form {
      PermissionSection(model: model)

      Section(model.copy.privacy) {
        Label(model.copy.noKeyLogging, systemImage: "checkmark.shield")
        Label(model.copy.noFullURLStorage, systemImage: "checkmark.shield")
        Label(model.copy.noTelemetry, systemImage: "checkmark.shield")
      }
    }
    .formStyle(.grouped)
  }
}

private struct SettingsInspector: View {
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    Form {
      Section(model.copy.shortcutGuide) {
        Label(model.copy.showShortcutGuideOnHold, systemImage: "command")
        Text(model.copy.holdToKeepGuideVisible)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section(model.copy.privacy) {
        Label(model.copy.noKeyLogging, systemImage: "checkmark.shield")
        Label(model.copy.screenSharingBestEffort, systemImage: "eye.slash")
      }
    }
    .formStyle(.grouped)
  }
}

private struct PermissionSection: View {
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    Section(model.copy.accessibility) {
      Label(
        model.hasAccessibilityPermission
          ? model.copy.permissionGranted : model.copy.permissionRequired,
        systemImage: model.hasAccessibilityPermission
          ? "checkmark.circle.fill" : "exclamationmark.circle"
      )
      .foregroundStyle(model.hasAccessibilityPermission ? .secondary : .primary)

      if !model.hasAccessibilityPermission {
        Text(model.copy.permissionDescription)
          .font(.caption)
          .foregroundStyle(.secondary)
        Button(model.copy.requestPermission) { model.requestAccessibility() }
      }

      Button(model.copy.checkAgain) { model.refreshPermission() }
    }
  }
}

private struct ContentHeader: View {
  let title: String
  let subtitle: String

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(title)
        .font(.title2.weight(.semibold))
      Text(subtitle)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 22)
    .padding(.vertical, 18)
  }
}

private struct KeyBadge: View {
  let text: String
  var accessibilityLabel: String? = nil

  var body: some View {
    Text(text)
      .font(.caption.monospaced().weight(.medium))
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
      .accessibilityLabel(accessibilityLabel ?? "Shortcut \(text)")
  }
}

private func copyToPasteboard(_ value: String) {
  NSPasteboard.general.clearContents()
  NSPasteboard.general.setString(value, forType: .string)
}
