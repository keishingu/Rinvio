import AppKit
import QuickDrawCore
import SwiftUI

struct QuickDrawRootView: View {
  @ObservedObject var model: QuickDrawAppModel

  @State private var selectedActionID: String? = Action.mute.rawValue
  @State private var isInspectorPresented = true
  @State private var isDevelopmentExpanded = true

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
      ToolbarItem(placement: .primaryAction) {
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
      normalizeActionSelection(for: model.selectedSection ?? .meeting)
    }
    .onChange(of: model.selectedSection) { _, section in
      normalizeActionSelection(for: section ?? .meeting)
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification))
    {
      _ in
      model.refreshConfiguredSystemShortcuts()
    }
  }

  private var selectedAction: ActionDefinition? {
    let definitions = actionDefinitions(for: model.selectedSection ?? .meeting)
    return definitions.first { $0.id == selectedActionID } ?? definitions.first
  }

  private var sidebar: some View {
    List(selection: $model.selectedSection) {
      Section(model.copy.actions) {
        ForEach([QuickDrawSection.meeting, .chat, .mail]) { section in
          Label(model.copy.sectionTitle(section), systemImage: section.systemImage)
            .tag(section)
        }

        DisclosureGroup(isExpanded: $isDevelopmentExpanded) {
          ForEach(QuickDrawSection.developmentSections) { section in
            Label(model.copy.sectionTitle(section), systemImage: section.systemImage)
              .tag(section)
          }
        } label: {
          Label(
            model.copy.sectionTitle(.development),
            systemImage: QuickDrawSection.development.systemImage
          )
        }

        Label(
          model.copy.sectionTitle(.browser),
          systemImage: QuickDrawSection.browser.systemImage
        )
        .tag(QuickDrawSection.browser)

        ForEach([QuickDrawSection.finder, .system]) { section in
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
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .center, spacing: 8) {
          Label(
            model.isEnabled ? model.copy.quickDrawEnabled : model.copy.quickDrawPaused,
            systemImage: model.isEnabled ? "checkmark.circle.fill" : "pause.circle"
          )
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.85)

          Spacer(minLength: 4)

          Toggle(
            "QuickDraw",
            isOn: Binding(
              get: { model.isEnabled },
              set: model.setEnabled
            )
          )
          .labelsHidden()
          .toggleStyle(.switch)
          .fixedSize()
          .frame(minWidth: 44, minHeight: 44)
          .accessibilityLabel("QuickDraw")
          .accessibilityValue(model.isEnabled ? model.copy.enabled : model.copy.paused)
          .help(model.isEnabled ? model.copy.pauseQuickDraw : model.copy.enableQuickDraw)
        }

        Text(model.triggerSummary)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      .padding(12)
    }
  }

  @ViewBuilder
  private var detail: some View {
    switch model.selectedSection ?? .meeting {
    case .system:
      if let domain = QuickDrawSection.system.actionDomain {
        ActionsView(
          title: model.copy.sectionTitle(.system),
          subtitle: model.copy.actionDomainSubtitle(domain),
          definitions: actionDefinitions(for: .system),
          applications: [],
          alignmentCategory: nil,
          selection: $selectedActionID,
          model: model
        )
      }
    case .finder, .meeting, .chat, .mail, .development, .developmentAIAgent, .developmentEditor,
      .developmentTerminal, .browser:
      let section = model.selectedSection ?? .meeting
      if let domain = section.actionDomain {
        ActionsView(
          title: model.copy.sectionTitle(section),
          subtitle: section.developmentCategory.map(
            model.copy.developmentApplicationCategorySubtitle
          ) ?? model.copy.actionDomainSubtitle(domain),
          definitions: actionDefinitions(for: section),
          applications: installedApplications(for: section),
          alignmentCategory: section.developmentCategory,
          selection: $selectedActionID,
          model: model
        )
      }
    case .applications:
      ApplicationsView(selection: $model.selectedApplicationID, model: model)
    case .settings:
      SettingsView(model: model)
    case .diagnostics:
      DiagnosticsView(model: model)
    }
  }

  @ViewBuilder
  private var inspector: some View {
    switch model.selectedSection ?? .meeting {
    case .system:
      if let selectedAction {
        SystemActionInspector(definition: selectedAction, model: model)
      } else {
        ContentUnavailableView(
          model.copy.noActionsInCategory,
          systemImage: QuickDrawSection.system.systemImage
        )
      }
    case .finder, .meeting, .chat, .mail, .development, .developmentAIAgent, .developmentEditor,
      .developmentTerminal, .browser:
      if let selectedAction {
        ActionInspector(
          definition: selectedAction,
          applications: installedApplications(for: model.selectedSection ?? .meeting),
          model: model
        )
      } else {
        ContentUnavailableView(
          model.copy.noActionsInCategory,
          systemImage: (model.selectedSection ?? .meeting).systemImage
        )
      }
    case .applications:
      if let application = model.applications.first(where: {
        $0.id == model.selectedApplicationID?.split(separator: ":").last.map(String.init)
      })
        ?? model.applications.first
      {
        if application.target == .macOS {
          SystemSettingsApplicationInspector(application: application, model: model)
        } else {
          ApplicationInspector(
            application: application,
            model: model
          )
        }
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
    let definitions = actionDefinitions(for: section)
    guard !definitions.contains(where: { $0.id == selectedActionID }) else { return }
    selectedActionID = definitions.first?.id
  }

  private func actionDefinitions(for section: QuickDrawSection) -> [ActionDefinition] {
    guard let domain = section.actionDomain else { return [] }
    let definitions = model.actions(in: domain)
    guard let category = section.developmentCategory else { return definitions }
    let applications = model.developmentApplications(in: category)
    return definitions.filter { definition in
      applications.contains { application in
        model.shortcut(for: definition.action, target: application.target) != nil
      }
    }
  }

  private func installedApplications(for section: QuickDrawSection) -> [ApplicationMapping] {
    guard let domain = section.actionDomain else { return [] }
    let applications = model.installedApplications(in: domain)
    guard let category = section.developmentCategory else { return applications }
    return applications.filter { category.contains($0.target) }
  }
}

private struct SettingsView: View {
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    VStack(spacing: 0) {
      ContentHeader(
        title: model.copy.settings,
        subtitle: model.copy.settingsSubtitle
      )
      Divider()

      Form {
        Section {
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
          .pickerStyle(.menu)
          .help(model.copy.chooseLanguage)
        }

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

        Section(model.copy.developerMode) {
          Toggle(
            model.copy.developerMode,
            isOn: Binding(
              get: { model.isDeveloperModeEnabled },
              set: model.setDeveloperModeEnabled
            )
          )
          Text(model.copy.developerModeDescription)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Section(model.copy.aboutQuickDraw) {
          LabeledContent(model.copy.productName, value: "QuickDraw Shortcuts")
          LabeledContent(model.copy.version, value: model.versionDescription)
          LabeledContent(model.copy.copyright, value: "© 2026 Kei Shingu")
          Button(model.copy.privacyPolicy) {
            model.openPrivacyPolicy()
          }
          Button(model.copy.support) {
            model.openSupport()
          }
        }
      }
      .formStyle(.grouped)
    }
    .navigationTitle("QuickDraw Shortcuts")
  }
}

private struct ActionsView: View {
  let title: String
  let subtitle: String
  let definitions: [ActionDefinition]
  let applications: [ApplicationMapping]
  let alignmentCategory: DevelopmentApplicationCategory?
  @Binding var selection: String?
  @ObservedObject var model: QuickDrawAppModel

  private var categories: [ActionCategory] {
    ActionCategory.allCases.filter { category in
      definitions.contains { $0.category == category }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      ContentHeader(
        title: title,
        subtitle: subtitle
      )
      if alignmentCategory != nil {
        alignmentControls
      }
      Divider()

      List(selection: $selection) {
        ForEach(categories) { category in
          Section(model.copy.actionCategoryName(category)) {
            ForEach(definitions.filter { $0.category == category }) { definition in
              ActionRow(
                definition: definition,
                applications: applications,
                model: model
              )
              .tag(definition.id)
            }
          }
        }
      }
      .listStyle(.inset)
    }
    .navigationTitle("QuickDraw")
  }

  private var alignmentControls: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        VStack(alignment: .leading, spacing: 4) {
          Label(model.copy.alignDevelopmentTriggers, systemImage: "keyboard")
            .font(.headline)
          Text(model.copy.alignDevelopmentTriggersDescription)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 8)

        if !applications.isEmpty {
          ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) {
              ForEach(applications) { application in
                alignmentButton(for: application)
              }
            }

            Menu(model.copy.alignDevelopmentTriggers) {
              ForEach(applications) { application in
                Button(model.copy.alignTriggersTo(application)) {
                  model.alignDevelopmentTriggers(to: application)
                }
              }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
          }
        }
      }

      if let error = model.shortcutEditingError {
        Label(error, systemImage: "exclamationmark.triangle.fill")
          .font(.caption)
          .foregroundStyle(.red)
      } else if let notice = model.triggerAlignmentNotice {
        Label(model.copy.triggerAlignmentNotice(notice), systemImage: "checkmark.circle.fill")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 22)
    .padding(.bottom, 12)
  }

  private func alignmentButton(for application: ApplicationMapping) -> some View {
    Button(model.copy.alignTriggersTo(application)) {
      model.alignDevelopmentTriggers(to: application)
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
    .fixedSize()
  }
}

private struct ActionRow: View {
  let definition: ActionDefinition
  let applications: [ApplicationMapping]
  @ObservedObject var model: QuickDrawAppModel

  private var displayedShortcut: KeyStroke? {
    ActionCatalog.isSystemWide(definition.action)
      ? model.configuredSystemShortcut(for: definition.action)
      : model.trigger(for: definition.action)
  }

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
            if let trigger = displayedShortcut {
              KeyBadge(
                text: trigger.displayValue,
                accessibilityLabel:
                  "\(model.copy.shortcutAccessibilityPrefix) \(trigger.displayValue)"
              )
              if !ActionCatalog.isSystemWide(definition.action)
                && !model.triggerConflicts(for: definition.action).isEmpty
              {
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
              Text(
                ActionCatalog.isSystemWide(definition.action)
                  ? model.copy.notConfigured : model.copy.unassigned
              )
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
        ForEach(applications) { application in
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

      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(ActionDomain.allCases.filter { ![.system, .finder].contains($0) }) { domain in
            domainHeader(domain)

            if domain == .development {
              ForEach(DevelopmentApplicationCategory.allCases) { category in
                developmentCategoryHeader(category)
                ForEach(model.developmentApplications(in: category)) { application in
                  applicationRow(application, in: domain)
                }
              }
            } else {
              ForEach(model.applications(in: domain)) { application in
                applicationRow(application, in: domain)
              }
            }
          }

          domainHeader(.system)
          ForEach([ActionTarget.finder, .macOS], id: \.rawValue) { target in
            if let application = model.applications.first(where: { $0.target == target }) {
              applicationRow(application, in: .system)
            }
          }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 12)
      }
    }
    .navigationTitle("QuickDraw")
  }

  private func domainHeader(_ domain: ActionDomain) -> some View {
    Text(domain == .system ? model.copy.systemSection : model.copy.actionDomainName(domain))
      .font(.caption.weight(.semibold))
      .foregroundStyle(.secondary)
      .padding(.horizontal, 8)
      .padding(.top, 14)
      .padding(.bottom, 5)
  }

  private func developmentCategoryHeader(_ category: DevelopmentApplicationCategory) -> some View {
    Text(model.copy.developmentApplicationCategoryName(category))
      .font(.headline)
      .padding(.horizontal, 8)
      .padding(.top, 8)
      .padding(.bottom, 4)
  }

  private func applicationRow(
    _ application: ApplicationMapping,
    in domain: ActionDomain
  ) -> some View {
    let rowID = "\(domain.rawValue):\(application.id)"
    let isSelected = selection == rowID
    let isEnabled = model.isApplicationEnabled(application.target)
    let isManagedBySystemSettings = application.target == .macOS

    return HStack(spacing: 8) {
      Button {
        selection = rowID
      } label: {
        HStack(spacing: 13) {
          Image(systemName: application.systemImage)
            .font(.title3)
            .symbolRenderingMode(.hierarchical)
            .frame(width: 36, height: 36)
            .background(
              isSelected ? Color.white.opacity(0.16) : Color.primary.opacity(0.08),
              in: RoundedRectangle(cornerRadius: 8)
            )

          VStack(alignment: .leading, spacing: 3) {
            Text(application.name)
              .font(.headline)
            Text(application.identity)
              .font(.caption)
              .foregroundStyle(isSelected ? Color.white.opacity(0.78) : Color.secondary)
          }

          Spacer()

          VStack(alignment: .trailing, spacing: 3) {
            Text(model.copy.actionCount(model.supportedActionCount(for: application.target)))
            Text(
              isManagedBySystemSettings
                ? model.copy.managedBySystemSettings
                : application.isInstalled
                  ? (isEnabled ? model.copy.detected : model.copy.excluded)
                  : model.copy.notInstalled
            )
            .font(.caption)
            .foregroundStyle(isSelected ? Color.white.opacity(0.78) : Color.secondary)
          }
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.leading, 8)
        .padding(.vertical, 7)
      }
      .buttonStyle(.plain)

      if isManagedBySystemSettings {
        Button(model.copy.openSystemShortcutSettings) {
          model.openSystemShortcutSettings()
        }
        .controlSize(.small)
        .padding(.trailing, 8)
      } else if application.isInstalled {
        Toggle(
          model.copy.quickDrawTarget,
          isOn: Binding(
            get: { model.isApplicationEnabled(application.target) },
            set: { model.setApplicationEnabled($0, for: application.target) }
          )
        )
        .labelsHidden()
        .toggleStyle(.switch)
        .controlSize(.small)
        .help(model.copy.quickDrawTarget)
        .padding(.trailing, 8)
      }
    }
    .opacity(application.isInstalled && !isEnabled && !isManagedBySystemSettings ? 0.65 : 1)
    .background(
      isSelected ? Color.accentColor : Color.clear,
      in: RoundedRectangle(cornerRadius: 8)
    )
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
          if model.isDeveloperModeEnabled {
            LabeledContent(
              model.copy.globalShortcut,
              value: model.areHotKeysRegistered
                ? model.copy.hotKeysRegistered(model.registeredTriggerSummary)
                : model.copy.unavailable
            )
          }
        }

        if model.isDeveloperModeEnabled {
          Section(model.copy.developerTools) {
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
      }
      .formStyle(.grouped)
    }
    .navigationTitle("QuickDraw")
  }
}

private struct ActionInspector: View {
  let definition: ActionDefinition
  let applications: [ApplicationMapping]
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
            Button(
              model.trigger(for: definition.action) == nil
                ? model.copy.assignShortcut : model.copy.changeShortcut
            ) {
              model.beginRecording(.trigger(definition.action))
            }
            if model.trigger(for: definition.action) != nil {
              Button(model.copy.unassignShortcut) {
                model.unassignTrigger(for: definition.action)
              }
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
        if applications.isEmpty {
          Label(model.copy.noInstalledApplications, systemImage: "app.dashed")
            .foregroundStyle(.secondary)
        } else {
          ForEach(applications) { application in
            MappingRow(
              application: application,
              action: definition.action,
              model: model
            )
          }
        }
      }

      if model.hasOverrides(for: definition.action) {
        Section {
          Button(model.copy.restoreActionDefaults) {
            isResetConfirmationPresented = true
          }
        }
      }

      if model.isDeveloperModeEnabled {
        Section(model.copy.developerTools) {
          Button(model.copy.testLastActiveApplication) {
            model.runDryCheck(action: definition.action)
          }
          .disabled(!model.isEnabled)
        }
      }
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

private struct SystemActionInspector: View {
  let definition: ActionDefinition
  @ObservedObject var model: QuickDrawAppModel

  private var configuredShortcut: KeyStroke? {
    model.configuredSystemShortcut(for: definition.action)
  }

  private var suggestedShortcut: KeyStroke? {
    ActionCatalog.defaultTrigger(for: definition.action)
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
            Text(model.copy.managedBySystemSettings)
              .foregroundStyle(.secondary)
          }
        }
      }

      Section(model.copy.systemShortcutConfiguration) {
        LabeledContent(model.copy.currentShortcut) {
          if let configuredShortcut {
            KeyBadge(text: configuredShortcut.displayValue)
          } else {
            Text(model.copy.notConfigured)
              .foregroundStyle(.secondary)
          }
        }
        LabeledContent(model.copy.suggestedShortcut) {
          if let suggestedShortcut {
            KeyBadge(text: suggestedShortcut.displayValue)
          }
        }

        if let configuredShortcut, let suggestedShortcut,
          configuredShortcut.matchesPhysicalShortcut(suggestedShortcut)
        {
          Label(model.copy.systemShortcutConfigured, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
        } else {
          Label(model.copy.systemShortcutNeedsReview, systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.orange)
        }

        Button(model.copy.openSystemShortcutSettings) {
          model.openSystemShortcutSettings()
        }
        Button(model.copy.refresh) {
          model.refreshConfiguredSystemShortcuts()
        }
        Text(model.copy.systemShortcutSettingsDescription)
          .font(.caption)
          .foregroundStyle(.secondary)
        if let warning = model.copy.systemShortcutReplacementWarning(for: definition.action) {
          Label(warning, systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(.orange)
        }
      }
    }
    .formStyle(.grouped)
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

      if application.isInstalled {
        Section {
          Toggle(
            model.copy.quickDrawTarget,
            isOn: Binding(
              get: { model.isApplicationEnabled(application.target) },
              set: { model.setApplicationEnabled($0, for: application.target) }
            )
          )
          Text(model.copy.quickDrawTargetDescription)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      if !application.isInstalled {
        Section {
          Label(model.copy.installToUseMappings, systemImage: "arrow.down.app")
            .foregroundStyle(.secondary)
          if let officialURL = application.officialURL {
            Link(destination: officialURL) {
              Label(model.copy.openOfficialWebsite, systemImage: "arrow.up.right.square")
            }
          }
        }
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

      if model.isDeveloperModeEnabled {
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
    }
    .formStyle(.grouped)
  }
}

private struct SystemSettingsApplicationInspector: View {
  let application: ApplicationMapping
  @ObservedObject var model: QuickDrawAppModel

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
            Text(model.copy.managedBySystemSettings)
              .foregroundStyle(.secondary)
          }
        }
      }

      Section(model.copy.systemShortcutConfiguration) {
        Text(model.copy.systemShortcutSettingsDescription)
          .foregroundStyle(.secondary)
        Button(model.copy.openSystemShortcutSettings) {
          model.openSystemShortcutSettings()
        }
        Button(model.copy.refresh) {
          model.refreshConfiguredSystemShortcuts()
        }
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
        Label(model.copy.screenSharingBestEffort, systemImage: "eye.slash")
        Text(model.copy.screenSharingLimitation)
          .font(.caption)
          .foregroundStyle(.secondary)
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
    }
    .formStyle(.grouped)
  }
}

private struct PermissionSection: View {
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    Section(model.copy.inputMonitoring) {
      Label(
        model.hasInputMonitoringPermission
          ? model.copy.permissionGranted : model.copy.permissionRequired,
        systemImage: model.hasInputMonitoringPermission
          ? "checkmark.circle.fill" : "exclamationmark.circle"
      )
      .foregroundStyle(model.hasInputMonitoringPermission ? .secondary : .primary)

      if !model.hasInputMonitoringPermission {
        Text(model.copy.inputMonitoringDescription)
          .font(.caption)
          .foregroundStyle(.secondary)
        Button(model.copy.requestInputMonitoring) { model.requestInputMonitoring() }
      }
    }

    Section(model.copy.shortcutDelivery) {
      Label(
        model.hasPostEventPermission
          ? model.copy.permissionGranted : model.copy.permissionRequired,
        systemImage: model.hasPostEventPermission
          ? "checkmark.circle.fill" : "exclamationmark.circle"
      )
      .foregroundStyle(model.hasPostEventPermission ? .secondary : .primary)

      if !model.hasPostEventPermission {
        Text(model.copy.shortcutDeliveryDescription)
          .font(.caption)
          .foregroundStyle(.secondary)
        Button(model.copy.requestShortcutDelivery) { model.requestPostEvent() }
      }

      Button(model.copy.checkAgain) { model.refreshPermissions() }
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
