import AppKit
import SwiftUI

struct MenuSwitchView: View {
    @ObservedObject var viewModel: MenuSwitchViewModel
    let onRevealSettings: () -> Void
    let onRevealFolder: () -> Void
    let onQuit: () -> Void

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
        .frame(width: 980, height: 760)
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.snappy(duration: 0.2), value: viewModel.page)
        .animation(.snappy(duration: 0.2), value: viewModel.settings.profiles.count)
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MenuSwitch")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Choose a configured model, or edit the full profile settings below.")
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

                Button("Open settings") {
                    viewModel.page = .settings
                }
                Button("Reveal settings file") { onRevealSettings() }
                Button("Open folder") { onRevealFolder() }
                Button("Quit") { onQuit() }
            }
        }
        .padding(20)
    }

    private var switcherPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard

                if viewModel.switcherEmptyState {
                    EmptyState(
                        title: "No enabled models",
                        message: "Open Settings and enable at least one profile to make the switch page useful."
                    )
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(viewModel.enabledProfiles) { profile in
                            SwitchCard(profile: profile, isActive: viewModel.currentProfile?.id == profile.id) {
                                viewModel.apply(profile: profile)
                            } onSelect: {
                                viewModel.selectProfile(profile)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.activeProfileLabel)
                        .font(.system(size: 18, weight: .semibold))
                    Text(viewModel.settingsSummary)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Badge(text: "Claude models hidden", isProminent: true)
            }

            Text("The switch page only shows profiles you configured in Settings.")
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

    private var settingsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsHeader

                VStack(alignment: .leading, spacing: 12) {
                    ForEach($viewModel.settings.profiles) { $profile in
                        ProfileEditorCard(
                            profile: $profile,
                            keyDraft: viewModel.keyBinding(for: profile.id),
                            storedKeyStatus: viewModel.storedKeyStatus(for: profile.id),
                            onSaveKey: {
                                viewModel.saveKey(for: profile.id, key: viewModel.keyDrafts[profile.id, default: ""])
                            },
                            onClearKey: {
                                viewModel.clearKey(for: profile.id)
                            },
                            onApply: {
                                viewModel.apply(profile: profile)
                            },
                            onDelete: {
                                viewModel.removeProfile(id: profile.id)
                            }
                        )
                    }
                }
            }
            .padding(18)
        }
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Edit the model name, endpoint, notes, and Keychain-backed API key for each profile.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Badge(text: "Form-based editor", isProminent: true)
            }

            HStack(spacing: 8) {
                Button("Add custom model") {
                    viewModel.addCustomProfile()
                }
                Button("Restore defaults") {
                    viewModel.restoreDefaults()
                }
                Button("Save settings") {
                    viewModel.saveSettings()
                }

                Spacer()

                Text("Claude models are hidden because Claude Code already provides them.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
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

private struct SwitchCard: View {
    let profile: MenuSwitchProfile
    let isActive: Bool
    let onSwitch: () -> Void
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.system(size: 13, weight: .semibold))
                    Text(profile.provider)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Badge(text: profile.requiresEndpoint ? "Gateway" : "Direct", isProminent: profile.enabled)
            }

            Text(profile.modelID)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(profile.notes)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack(spacing: 8) {
                Button("Select") {
                    onSelect()
                }

                Button("Switch now") {
                    onSwitch()
                }
                .keyboardShortcut(.defaultAction)

                Spacer()

                if isActive {
                    Badge(text: "Active", isProminent: true)
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

private struct ProfileEditorCard: View {
    @Binding var profile: MenuSwitchProfile
    let keyDraft: Binding<String>
    let storedKeyStatus: String
    let onSaveKey: () -> Void
    let onClearKey: () -> Void
    let onApply: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    LabeledField(label: "Display name", helpText: "Shown on the switch page.", text: $profile.name, placeholder: "DeepSeek V4 Pro")
                    LabeledField(label: "Provider", helpText: "Shown beside the model name.", text: $profile.provider, placeholder: "DeepSeek")
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Toggle(isOn: $profile.enabled) {
                        Text("Enabled")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .toggleStyle(.switch)

                    Badge(text: profile.requiresEndpoint ? "Gateway" : "Direct", isProminent: profile.enabled)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                LabeledField(label: "Model ID", helpText: "This is the exact model string Claude Code will use.", text: $profile.modelID, placeholder: "qwen3.6-plus")
                LabeledField(label: "Endpoint or gateway URL", helpText: profile.requiresEndpoint ? "Required for this profile." : "Optional for direct endpoints.", text: $profile.endpoint, placeholder: "https://your-gateway.example.com/anthropic")
                LabeledField(label: "Docs URL", helpText: "Used for the help link on this card.", text: $profile.docsURL, placeholder: "https://example.com/docs")
                LabeledTextEditor(label: "Notes", helpText: "Short setup notes for this profile.", text: $profile.notes)
            }

            HStack(spacing: 8) {
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
                    Button("Delete") {
                        onDelete()
                    }
                }
                .buttonStyle(.borderless)
            }
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
                .frame(minHeight: 86)
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
