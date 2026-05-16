import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MenuSwitchView: View {
    @ObservedObject var viewModel: MenuSwitchViewModel
    let onRevealSettings: () -> Void
    let onRevealFolder: () -> Void
    let onQuit: () -> Void
    let onPageChange: (MenuSwitchPage) -> Void

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
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.snappy(duration: 0.22), value: viewModel.page)
        .onAppear { onPageChange(viewModel.page) }
        .onChange(of: viewModel.page) { onPageChange($0) }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MenuSwitch")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Switch configured models quickly. Open Settings to edit the full profile editor.")
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

            if let error = viewModel.lastErrorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                    Spacer()
                    Button("Dismiss") { viewModel.lastErrorMessage = nil }
                        .font(.system(size: 11))
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                    note: "Only enabled profiles appear here. Tap a card anywhere to switch it immediately."
                )

                if viewModel.switcherEmptyState {
                    EmptyState(
                        title: "No enabled profiles",
                        message: "Open the Settings page, enable a profile, and save changes to populate this switchboard."
                    )
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.enabledProfiles) { profile in
                            SelectableSwitchCard(
                                profile: profile,
                                isActive: viewModel.currentProfile?.id == profile.id,
                                action: {
                                    viewModel.apply(profile: profile)
                                }
                            )
                        }
                    }
                }

                RestoreDefaultsButton {
                    viewModel.resetClaudeCodeSettings()
                }
            }
            .padding(16)
        }
    }

    private var settingsPage: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: selectedProfileSelectionBinding) {
                    Section("Profiles") {
                        ForEach(viewModel.configuredProfiles) { profile in
                            SettingsSidebarRow(
                                profile: profile,
                                isSelected: viewModel.settings.selectedProfileID == profile.id,
                                isDragging: viewModel.draggedProfileID == profile.id,
                                onSelect: {
                                    viewModel.selectProfile(profile)
                                },
                                onToggleEnabled: { enabled in
                                    viewModel.setEnabled(enabled, for: profile.id)
                                },
                                onDelete: {
                                    viewModel.removeProfile(id: profile.id)
                                }
                            )
                            .tag(profile.id as String?)
                            .onDrag {
                                let pid = profile.id
                                viewModel.draggedProfileID = pid
                                return NSItemProvider(object: pid as NSString)
                            }
                            .onDrop(of: [UTType.text], isTargeted: nil) { _ in
                                guard let sourceID = viewModel.draggedProfileID else {
                                    return false
                                }
                                viewModel.draggedProfileID = nil
                                viewModel.moveProfile(from: sourceID, before: profile.id)
                                return true
                            }
                        }
                    }
                }
                .listStyle(.sidebar)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Menu("Add profile") {
                        Button("Blank custom model") {
                            viewModel.addCustomProfile()
                        }
                        Divider()
                        ForEach(ModelTemplateCatalog.templates, id: \.id) { template in
                            Button("From \(template.name)") {
                                viewModel.addProfile(from: template)
                            }
                        }
                    }
                    Button("Restore defaults") {
                        viewModel.restoreDefaults()
                    }
                    Button("Save settings") {
                        viewModel.saveSettings()
                    }

                    Text("Drag the handle to reorder. Tap Apply on any profile to activate it in Claude Code.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(.borderless)
                .padding(12)
            }
            .frame(minWidth: 260)
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
                        },
                        onToggleEnabled: { enabled in
                            viewModel.setEnabled(enabled, for: binding.wrappedValue.id)
                        },
                        aliasBinding: { key in
                            viewModel.environmentBinding(profileID: binding.wrappedValue.id, key: key, scope: .alias)
                        },
                        runtimeBinding: { key in
                            viewModel.environmentBinding(profileID: binding.wrappedValue.id, key: key, scope: .runtime)
                        }
                    )
                } else {
                    EmptyState(
                        title: "Select a profile",
                        message: "Choose a profile from the sidebar to edit its full endpoint, notes, environment overrides, and Keychain-backed key."
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
                    Text("Pick a profile on the left, then edit the full configuration on the right.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Badge(text: "Form-based editor", isProminent: true)
            }

            Text("Claude models are intentionally hidden here because they are already built into Claude Code.")
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
        guard let selectedID = viewModel.settings.selectedProfileID else {
            return nil
        }
        return viewModel.profileBinding(for: selectedID)
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

private struct SelectableSwitchCard: View {
    let profile: MenuSwitchProfile
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
                    Badge(text: isActive ? "Active" : "Tap to switch", isProminent: isActive)
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
        .buttonStyle(MenuSwitchSelectableButtonStyle())
    }
}

private struct SettingsSidebarRow: View {
    let profile: MenuSwitchProfile
    let isSelected: Bool
    let isDragging: Bool
    let onSelect: () -> Void
    let onToggleEnabled: (Bool) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)

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

            Spacer(minLength: 8)

            Toggle("", isOn: Binding(
                get: { profile.enabled },
                set: { onToggleEnabled($0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(profile.templateID == nil ? .red : .secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isSelected ? Color.accentColor.opacity(0.10) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .opacity(isDragging ? 0.7 : 1)
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
    let onToggleEnabled: (Bool) -> Void
    let aliasBinding: (String) -> Binding<String>
    let runtimeBinding: (String) -> Binding<String>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                EditorSection(title: "Identity") {
                    Toggle("Enabled on Switch page", isOn: Binding(
                        get: { profile.enabled },
                        set: { onToggleEnabled($0) }
                    ))
                    LabeledField(label: "Display name", helpText: "Shown in the switch page.", text: $profile.name, placeholder: "Model name")
                    LabeledField(label: "Provider", helpText: "Shown as the source label.", text: $profile.provider, placeholder: "Provider")
                    LabeledField(label: "Model ID", helpText: "The exact model string Claude Code should send.", text: $profile.modelID, placeholder: "model-name")
                }

                EditorSection(title: "Connection") {
                    EndpointQuickFill(endpoint: $profile.endpoint)
                    LabeledField(label: "Endpoint or gateway URL", helpText: profile.requiresEndpoint ? "Required for this profile." : "Optional — leave blank for Anthropic native.", text: $profile.endpoint, placeholder: "https://your-gateway.example.com/anthropic")
                    Toggle("Requires endpoint or gateway", isOn: $profile.requiresEndpoint)
                    LabeledField(label: "Docs URL", helpText: "Where the model setup reference lives.", text: $profile.docsURL, placeholder: "https://example.com/docs")
                    LabeledTextEditor(label: "Notes", helpText: "Short notes that explain how to use this profile.", text: $profile.notes)
                }

                EditorSection(title: "Claude Code aliases") {
                    ForEach([
                        "ANTHROPIC_DEFAULT_OPUS_MODEL",
                        "ANTHROPIC_DEFAULT_SONNET_MODEL",
                        "ANTHROPIC_DEFAULT_HAIKU_MODEL"
                    ], id: \.self) { key in
                        LabeledField(
                            label: key,
                            helpText: "Claude Code alias mapping for this profile.",
                            text: aliasBinding(key),
                            placeholder: "Model name"
                        )
                    }
                }

                EditorSection(title: "Runtime overrides") {
                    ForEach([
                        "CLAUDE_CODE_SUBAGENT_MODEL",
                        "CLAUDE_CODE_EFFORT_LEVEL",
                        "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY",
                        "ENABLE_TOOL_SEARCH"
                    ], id: \.self) { key in
                        LabeledField(
                            label: key,
                            helpText: "Runtime override stored with the profile.",
                            text: runtimeBinding(key),
                            placeholder: "Value"
                        )
                    }
                }

                EditorSection(title: "API access") {
                    PasteableInput(label: "API key", helpText: storedKeyStatus, text: keyDraft, placeholder: "Paste a key to save it in Keychain")

                    HStack(spacing: 8) {
                        Button("Save key") {
                            onSaveKey()
                        }
                        Button("Clear key") {
                            onClearKey()
                        }
                        Button("Apply now") {
                            onApply()
                        }
                    }
                    .buttonStyle(.bordered)
                }

                EditorSection(title: "Danger zone") {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Text("Delete profile")
                    }
                    Text("Delete removes this profile from MenuSwitch. Custom profiles can be recreated at any time.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct EditorSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
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
                .multilineTextAlignment(.leading)
            Text(helpText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .scrollContentBackground(.hidden)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
            Text(helpText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PasteableInput: View {
    let label: String
    let helpText: String
    @Binding var text: String
    let placeholder: String
    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Group {
                    if isRevealed {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .textFieldStyle(.roundedBorder)
                Button(action: { isRevealed.toggle() }) {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                }
                .buttonStyle(.plain)
                .help(isRevealed ? "Hide key" : "Reveal key")
            }
            Text(helpText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private let knownProviderEndpoints: [(name: String, url: String)] = [
    ("Anthropic native (no URL)", ""),
    ("DeepSeek", "https://api.deepseek.com/anthropic"),
    ("Moonshot / Kimi", "https://api.moonshot.ai/anthropic"),
    ("MiniMax", "https://api.minimaxi.com/anthropic"),
    ("OpenRouter", "https://openrouter.ai/api/v1"),
    ("Custom...", "__custom__"),
]

private struct EndpointQuickFill: View {
    @Binding var endpoint: String
    @State private var selection: String = "__custom__"

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Provider preset")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Picker("", selection: $selection) {
                ForEach(knownProviderEndpoints, id: \.url) { item in
                    Text(item.name).tag(item.url)
                }
            }
            .labelsHidden()
            .onChange(of: selection) { newValue in
                if newValue != "__custom__" {
                    endpoint = newValue
                }
            }
            Text("Choose a provider to auto-fill the endpoint URL below, then adjust as needed.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
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

private struct RestoreDefaultsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Restore Claude Code defaults")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Clears all third-party model, key, and endpoint overrides from ~/.claude/settings.json")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.orange.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.orange.opacity(0.30), lineWidth: 1)
            )
        }
        .buttonStyle(MenuSwitchSelectableButtonStyle())
        .foregroundStyle(.orange)
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

private struct MenuSwitchSelectableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
