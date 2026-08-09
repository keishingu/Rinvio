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
        HStack(spacing: 7) {
          Text(model.isEnabled ? "Enabled" : "Paused")
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
        .help(model.isEnabled ? "Pause QuickDraw" : "Enable QuickDraw")

        Button {
          isInspectorPresented.toggle()
        } label: {
          Label("Inspector", systemImage: "sidebar.trailing")
        }
        .help(isInspectorPresented ? "Hide Inspector" : "Show Inspector")
      }
    }
    .frame(minWidth: 860, minHeight: 560)
    .onAppear {
      model.refreshEnvironment()
    }
  }

  private var sidebar: some View {
    List(QuickDrawSection.allCases, selection: $selectedSection) { section in
      Label(section.title, systemImage: section.systemImage)
        .tag(section)
    }
    .navigationTitle("QuickDraw")
    .navigationSplitViewColumnWidth(min: 170, ideal: 200, max: 240)
    .safeAreaInset(edge: .bottom) {
      VStack(alignment: .leading, spacing: 5) {
        Label(
          model.isEnabled ? "QuickDraw is enabled" : "QuickDraw is paused",
          systemImage: model.isEnabled ? "checkmark.circle.fill" : "pause.circle"
        )
        .font(.caption)
        .foregroundStyle(.secondary)

        Text("F6 → Mute")
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
        ApplicationInspector(application: application)
      } else {
        ContentUnavailableView("No Applications", systemImage: "square.grid.2x2")
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
        title: "Actions",
        subtitle: "One action, translated for every supported application."
      )

      Divider()

      List(selection: $selection) {
        Section("Meeting controls") {
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
          Text("Mute Toggle")
            .font(.headline)
          KeyBadge(text: "F6")
        }
        Text("Mute or unmute the active meeting")
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
        title: "Applications",
        subtitle: "See how Mute is executed in each target."
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
            Text(application.isInstalled ? "Detected" : "Not installed")
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
        title: "Diagnostics",
        subtitle:
          "Routing metadata only. QuickDraw does not record your keystrokes or meeting URLs."
      )

      Divider()

      Form {
        Section("Current status") {
          LabeledContent("State", value: model.status.headline)
          LabeledContent("Target", value: model.status.target)
          LabeledContent("Result", value: model.status.detail)
          LabeledContent(
            "Global shortcut", value: model.isHotKeyRegistered ? "F6 registered" : "Unavailable")
        }

        Section("Recent routing log") {
          Text(model.diagnostics)
            .font(.caption.monospaced())
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)

          HStack {
            Button("Refresh") {
              model.refreshDiagnostics()
            }
            Button("Copy Diagnostics") {
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
            Text("Mute Toggle")
              .font(.title3.weight(.semibold))
            Text("Meeting control")
              .foregroundStyle(.secondary)
          }
        }
      }

      Section("Trigger") {
        LabeledContent("Global shortcut") {
          KeyBadge(text: "F6")
        }
        Text("Trigger editing will follow after the fixed F6 route is hardened.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section("Application mappings") {
        ForEach(model.applications) { application in
          MappingRow(application: application)
        }
      }

      Section("Execution") {
        Toggle(
          "Dry Run",
          isOn: Binding(
            get: { model.isDryRunEnabled },
            set: model.setDryRunEnabled
          )
        )
        Text("Dry Run resolves the target without sending a shortcut.")
          .font(.caption)
          .foregroundStyle(.secondary)

        Button("Test Last Active Application") {
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

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: application.systemImage)
        .frame(width: 22)
        .foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 2) {
        Text(application.name)
        Text(application.executionDetail)
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
            Text(application.isInstalled ? "Detected" : "Not installed")
              .foregroundStyle(.secondary)
          }
        }
      }

      Section("Identity") {
        Text(application.identity)
          .textSelection(.enabled)
      }

      Section("Mute mapping") {
        LabeledContent("Capability", value: "Supported")
        LabeledContent("Method", value: application.executionDetail)
        LabeledContent("Shortcut", value: application.shortcut)
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

      Section("Privacy") {
        Label("No key logging", systemImage: "checkmark.shield")
        Label("No full URL storage", systemImage: "checkmark.shield")
        Label("No telemetry", systemImage: "checkmark.shield")
      }
    }
    .formStyle(.grouped)
  }
}

private struct PermissionSection: View {
  @ObservedObject var model: QuickDrawAppModel

  var body: some View {
    Section("Accessibility") {
      Label(
        model.hasAccessibilityPermission ? "Permission granted" : "Permission required",
        systemImage: model.hasAccessibilityPermission
          ? "checkmark.circle.fill" : "exclamationmark.circle"
      )
      .foregroundStyle(model.hasAccessibilityPermission ? .secondary : .primary)

      if !model.hasAccessibilityPermission {
        Text("Required only to send the application shortcut after routing.")
          .font(.caption)
          .foregroundStyle(.secondary)
        Button("Request Permission…") {
          model.requestAccessibility()
        }
      }

      Button("Check Again") {
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

  var body: some View {
    Text(text)
      .font(.caption.monospaced().weight(.medium))
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
      .accessibilityLabel("Shortcut \(text)")
  }
}

private func copyToPasteboard(_ value: String) {
  NSPasteboard.general.clearContents()
  NSPasteboard.general.setString(value, forType: .string)
}
