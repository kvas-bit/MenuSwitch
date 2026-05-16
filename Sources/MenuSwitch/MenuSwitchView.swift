import AppKit
import SwiftUI

struct MenuSwitchView: View {
    @ObservedObject var viewModel: MenuSwitchViewModel
    let onRevealSettings: () -> Void
    let onRevealFolder: () -> Void
    let onQuit: () -> Void
    let onPageChange: (MenuSwitchPage) -> Void

    private var pageSize: CGSize {
        switch viewModel.page {
        case .switcher:
            return CGSize(width: 680, height: 460)
        case .settings:
            return CGSize(width: 1120, height: 780)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()

            switch viewModel.page {
            case .switcher:
                switcherPage
            case .settings:
                settingsPage
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.snappy(duration: 0.2), value: viewModel.page)
        .onAppear { onPageChange(viewModel.page) }
        .onChange(of: viewModel.page) { onPageChange($0) }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MenuSwitch")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Switch configured models quickly. Edit the full profile settings in the other page.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.statusText)
                        .font(.system(size: 12, weight: .semibold))
                    Text(viewModel.activeProfileSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Picker("", selection: $viewModel.page) {
                    ForEach(MenuSwitchPage.allCases) { page in
                        Text(page.rawValue).tag(page)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)

                Spacer()

                Button("Reveal settings file") { onRevealSettings() }
                Button("Open Claude folder") { onRevealFolder() }
                Button("Quit") { onQuit() }
            }
        }
        .padding(20)
    }

    private var switcherPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SummaryCard(
                    title: viewModel.activeProfileLabel,
                    subtitle: viewModel.settingsSummary,
                    note: "Only enabled profiles appear here. Claude models are hidden because Claude Code already includes them."
                )

                if viewModel.switcherEmptyState {
                    EmptyState(
                        title: "No enabled models",
                        message: "Open the Settings page, enable a profile, and save changes to populate this page."
                    )
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.enabledProfiles) { profile in
                            SwitchRow(
                                profile: profile,
                                isActive: viewModel.currentProfile?.id == profile.id,
                                onSelect: {
                                    viewModel.selectProfile(profile)
                                },
                                onSwitch: {
                                    viewModel.apply(profile: profile)
                                }
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var settingsPage: some View {
        NavigationSplitView {
            List(selection: selectedProfileSelectionBinding) {
                Section("Configured profiles") {
                    ForEach(viewModel.configuredProfiles) { profile in
                        SettingsSidebarRow(profile: profile)
                            .tag(profile.id as String?)
                    }
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Button("Add custom model") {
                        viewModel.addCustomProfile()
                    }
                    Button("Restore defaults") {
                        viewModel.restoreDefaults()
                    }
                    Button("Save settings") {
                        viewModel.saveSettings()
                    }
                }
                .buttonStyle(.borderless)
                .padding(12)
            }
            .frame(minWidth: 280)
        } detail: {
            VStack(alignment: .leading, spacing: 16) {
                settingsHeader

                if let binding = selectedProfileEditorBinding {
                    ProfileForm(
                        profile: binding,
                        keyDraft: viewModel.keyBinding(for: binding.wrappedValue.id),
                        storedKeyStatus: viewModel.storedKeyStatus(for: binding.wrappedValue.id),
                        onSaveKey: {
                            viewModel.saveKey(for: binding.wrappedValue.id, key: viewModel.keyDrafts[binding.wrappedValue.id, default: ""])
                        },
                        onClearKey: {
                            viewModel.clearKey(for: binding.wrappedValue.id)
                        },
                        onApply: {
                            viewModel.apply(profile: binding.wrappedValue)
                        },
                        onDelete: {
                            viewModel.removeProfile(id: binding.wrappedValue.id)
                        }
                    )
                } else {
                    EmptyState(
                        title: "Select a profile",
                        message: "Choose a configured model from the sidebar to edit its full endpoint, notes, and Keychain-backed key."
                    )
                }
            }
            .padding(18)
        }
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Apple-style split editor: pick a profile on the left, then edit the full configuration on the right.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Badge(text: "Form-based editor", isProminent: true)
            }

            Text("Claude models are intentionally hidden here because they are already available in Claude Code.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var selectedProfileSelectionBinding: Binding<String?> {
        Binding(
            get: { viewModel.settings.selectedProfileID },
            set: { viewModel.settings.selectedProfileID = $0 }
        )
    }

    private var selectedProfileEditorBinding: Binding<MenuSwitchProfile>? {
        guard let selectedID = viewModel.settings.selectedProfileID,
              let index = viewModel.settings.profiles.firstIndex(where: { $0.id == selectedID }) else {
            return nil
        }
        return $viewModel.settings.profiles[index]
    }
}

private struct SummaryCard: View {
    let title: String
    let subtitle: String
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Badge(text: "Switch page", isProminent: true)
            }

            Text(note)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct SwitchRow: View {
    let profile: MenuSwitchProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onSwitch: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 13, weight: .semibold))
                Text(profile.provider)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(profile.modelID)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(profile.notes)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 8) {
                Badge(text: profile.requiresEndpoint ? "Gateway" : "Direct", isProminent: profile.enabled)

                HStack(spacing: 8) {
                    Button("Details") {
                        onSelect()
                    }

                    Button("Switch now") {
                        onSwitch()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isActive ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isActive ? Color.accentColor.opacity(0.55) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct SettingsSidebarRow: View {
    let profile: MenuSwitchProfile

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name)
                    .font(.system(size: 12, weight: .semibold))
                Text(profile.provider)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(profile.modelID)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 4) {
                Badge(text: profile.enabled ? "On" : "Off", isProminent: profile.enabled)
                Badge(text: profile.requiresEndpoint ? "Gateway" : "Direct", isProminent: false)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ProfileForm: View {
    @Binding var profile: MenuSwitchProfile
    let keyDraft: Binding<String>
    let storedKeyStatus: String
    let onSaveKey: () -> Void
    let onClearKey: () -> Void
    let onApply: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Form {
            Section {
                Toggle("Enabled on Switch page", isOn: $profile.enabled)
                LabeledField(label: "Display name", helpText: "Shown on the switch page.", text: $profile.name, placeholder: "Qwen 3.6 Plus")
                LabeledField(label: "Provider", helpText: "Shown as the source label.", text: $profile.provider, placeholder: "Qwen")
                LabeledField(label: "Model ID", helpText: "The exact model string Claude Code should send.", text: $profile.modelID, placeholder: "qwen3.6-plus")
            }

            Section {
                LabeledField(label: "Endpoint or gateway URL", helpText: profile.requiresEndpoint ? "Required for this profile." : "Optional for direct provider endpoints.", text: $profile.endpoint, placeholder: "https://your-gateway.example.com/anthropic")
                LabeledField(label: "Docs URL", helpText: "Where the model setup reference lives.", text: $profile.docsURL, placeholder: "https://example.com/docs")
                LabeledTextEditor(label: "Notes", helpText: "Short notes that explain how to use this profile.", text: $profile.notes)
            }

            Section {
                HStack(alignment: .top, spacing: 12) {
                    SecureInput(label: "API key", helpText: storedKeyStatus, text: keyDraft, placeholder: "Paste a key to save it in Keychain")

                    VStack(alignment: .leading, spacing: 8) {
                        Button("Save Key") {
                            onSaveKey()
                        }
                        Button("Clear Key") {
                            onClearKey()
                        }
                        Button("Apply Now") {
                            onApply()
                        }
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Text("Delete profile")
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct LabeledField: View {
    let label: String
    let helpText: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
            Text(helpText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct LabeledTextEditor: View {
    let label: String
    let helpText: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            TextEditor(text: $text)
                .frame(minHeight: 84)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
            Text(helpText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

private struct SecureInput: View {
    let label: String
    let helpText: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            SecureField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
            Text(helpText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Badge: View {
    let text: String
    let isProminent: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(isProminent ? .primary : .secondary)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(isProminent ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08))
            .clipShape(Capsule())
    }
}

private struct EmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
