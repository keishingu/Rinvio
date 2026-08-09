import AppKit
import SwiftUI

struct QuickDrawRootView: View {
  @ObservedObject var model: QuickDrawAppModel

  @State private var selectedSection: QuickDrawSection? = .actions
  @State private var selectedActionID: String? = "meeting.mute"
  @State private var selectedApplicationID: String? = "microsoftTeams"
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
    }
  }

  private var sidebar: some View {
    List(QuickDrawSection.allCases, selection: $selectedSection) { section in
      Label(model.copy.sectionTitle(section), systemImage: section.systemImage)
        .tag(section)
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

        Text(model.copy.f6Mute)
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
    }
  }

  @ViewBuilder
  private var detail: some View {
    switch selectedSection ?? .actions {
    case .actions:
      ActionsView(selection: $selectedActionID, model: model)
    case .applications:
      ApplicationsView(selection: $selectedApplicationID, model: model)
    case .diagnostics:
      DiagnosticsView(model: model)
    }
  }

  @ViewBuilder
  private var inspector: some View {
    switch selectedSection ?? .actions {
    case .actions:
      MuteActionInspector(model: model)
    case .applications:
      if let application = model.applications.first(where: { $0.id == selectedApplicationID })
        ?? model.applications.first
      {
        ApplicationInspector(application: application, language: model.language)
      } else {
        ContentUnavailableView(model.copy.noApplications, systemImage: "square.grid.2x2")
      }
    case .diagnostics:
      DiagnosticsInspector(model: model)
    }
  }
}

private struct ActionsView: View {
  @Binding var selection: String?
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    VStack(spacing: 0) {
      ContentHeader(
        title: model.copy.actions,
        subtitle: model.copy.actionsSubtitle
      )

      Divider()

      List(selection: $selection) {
        Section(model.copy.meetingControls) {
          ActionRow(model: model)
            .tag("meeting.mute")
        }
      }
      .listStyle(.inset)
    }
    .navigationTitle("QuickDraw")
  }
}

private struct ActionRow: View {
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: "mic.slash.fill")
        .font(.title2)
        .symbolRenderingMode(.hierarchical)
        .frame(width: 38, height: 38)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Text(model.copy.muteToggle)
            .font(.headline)
          KeyBadge(
            text: "F6",
            accessibilityLabel: "\(model.copy.shortcutAccessibilityPrefix) F6"
          )
        }
        Text(model.copy.muteDescription)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 18)

      HStack(spacing: 18) {
        ForEach(model.applications) { application in
          CompactMapping(application: application)
        }
      }
    }
    .padding(.vertical, 9)
    .contentShape(Rectangle())
  }
}

private struct CompactMapping: View {
  let application: ApplicationMapping

  var body: some View {
    HStack(spacing: 7) {
      Image(systemName: application.systemImage)
        .frame(width: 18)
        .foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 1) {
        Text(application.compactName)
          .font(.caption)
          .lineLimit(1)
        Text(application.shortcut)
          .font(.caption2.monospaced())
          .foregroundStyle(.secondary)
      }
    }
    .frame(minWidth: 88, alignment: .leading)
  }
}

private struct ApplicationsView: View {
  @Binding var selection: String?
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    VStack(spacing: 0) {
      ContentHeader(
        title: model.copy.applications,
        subtitle: model.copy.applicationsSubtitle
      )

      Divider()

      List(model.applications, selection: $selection) { application in
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
            Text(application.shortcut)
              .font(.body.monospaced())
            Text(application.isInstalled ? model.copy.detected : model.copy.notInstalled)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.vertical, 7)
        .tag(application.id)
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
      ContentHeader(
        title: model.copy.diagnostics,
        subtitle: model.copy.diagnosticsSubtitle
      )

      Divider()

      Form {
        Section(model.copy.currentStatus) {
          LabeledContent(model.copy.state, value: model.localizedStatus.headline)
          LabeledContent(model.copy.target, value: model.localizedStatus.target)
          LabeledContent(model.copy.result, value: model.localizedStatus.detail)
          LabeledContent(
            model.copy.globalShortcut,
            value: model.isHotKeyRegistered ? model.copy.f6Registered : model.copy.unavailable
          )
        }

        Section(model.copy.recentRoutingLog) {
          Text(model.diagnostics)
            .font(.caption.monospaced())
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)

          HStack {
            Button(model.copy.refresh) {
              model.refreshDiagnostics()
            }
            Button(model.copy.copyDiagnostics) {
              copyToPasteboard(model.diagnostics)
            }
          }
        }
      }
      .formStyle(.grouped)
    }
    .navigationTitle("QuickDraw")
  }
}

private struct MuteActionInspector: View {
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    Form {
      Section {
        HStack(spacing: 12) {
          Image(systemName: "mic.slash.fill")
            .font(.title)
            .symbolRenderingMode(.hierarchical)
            .frame(width: 46, height: 46)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
          VStack(alignment: .leading, spacing: 3) {
            Text(model.copy.muteToggle)
              .font(.title3.weight(.semibold))
            Text(model.copy.meetingControl)
              .foregroundStyle(.secondary)
          }
        }
      }

      Section(model.copy.trigger) {
        LabeledContent(model.copy.globalShortcut) {
          KeyBadge(
            text: "F6",
            accessibilityLabel: "\(model.copy.shortcutAccessibilityPrefix) F6"
          )
        }
        Text(model.copy.triggerEditingDescription)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section(model.copy.applicationMappings) {
        ForEach(model.applications) { application in
          MappingRow(application: application, language: model.language)
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
          model.runDryCheck()
        }
        .disabled(!model.isEnabled)
      }

      PermissionSection(model: model)
    }
    .formStyle(.grouped)
  }
}

private struct MappingRow: View {
  let application: ApplicationMapping
  let language: AppLanguage

  private var copy: QuickDrawCopy { QuickDrawCopy(language: language) }

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: application.systemImage)
        .frame(width: 22)
        .foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 2) {
        Text(application.name)
        Text(copy.executionDetail(for: application))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Text(application.shortcut)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
    }
  }
}

private struct ApplicationInspector: View {
  let application: ApplicationMapping
  let language: AppLanguage

  private var copy: QuickDrawCopy { QuickDrawCopy(language: language) }

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
            Text(application.isInstalled ? copy.detected : copy.notInstalled)
              .foregroundStyle(.secondary)
          }
        }
      }

      Section(copy.identity) {
        Text(application.identity)
          .textSelection(.enabled)
      }

      Section(copy.muteMapping) {
        LabeledContent(copy.capability, value: copy.supported)
        LabeledContent(copy.method, value: copy.executionDetail(for: application))
        LabeledContent(copy.shortcut, value: application.shortcut)
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
        Button(model.copy.requestPermission) {
          model.requestAccessibility()
        }
      }

      Button(model.copy.checkAgain) {
        model.refreshPermission()
      }
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
