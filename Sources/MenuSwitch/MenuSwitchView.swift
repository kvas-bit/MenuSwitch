import AppKit
import SwiftUI

struct MenuSwitchView: View {
    @ObservedObject var viewModel: MenuSwitchViewModel
    let onRevealSettings: () -> Void
    let onRevealFolder: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                sidebar
                    .frame(width: 334)
                Divider()
                detailPane
            }
        }
        .frame(width: 980, height: 760)
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.snappy(duration: 0.2), value: viewModel.selectedPresetID)
        .animation(.snappy(duration: 0.2), value: viewModel.searchText)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MenuSwitch")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Switch Claude Code models without editing settings by hand.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.currentConnectionSummary)
                        .font(.system(size: 12, weight: .semibold))
                    Text(viewModel.statusText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                SearchField(text: $viewModel.searchText, placeholder: "Search models, providers, or notes")
                    .frame(maxWidth: .infinity)

                Button("Open settings") { onRevealSettings() }
                Button("Open folder") { onRevealFolder() }
                Button("Quit") { onQuit() }
            }
        }
        .padding(20)
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Recommended", subtitle: "Latest models to reach for first")

                LazyVStack(spacing: 8) {
                    ForEach(viewModel.recommendedPresets) { preset in
                        PresetRow(preset: preset, isSelected: viewModel.selectedPresetID == preset.id) {
                            viewModel.selectPreset(preset)
                        }
                    }
                }

                if !viewModel.sectionedPresets.isEmpty {
                    ForEach(viewModel.sectionedPresets, id: \.0) { section, presets in
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: section.rawValue, subtitle: sectionSubtitle(for: section))
                            LazyVStack(spacing: 8) {
                                ForEach(presets) { preset in
                                    PresetRow(preset: preset, isSelected: viewModel.selectedPresetID == preset.id) {
                                        viewModel.selectPreset(preset)
                                    }
                                }
                            }
                        }
                    }
                }

                SectionHeader(title: "Custom", subtitle: "Any Anthropic-compatible endpoint")
                PresetRow(
                    preset: viewModel.customPreset,
                    isSelected: viewModel.selectedPresetID == viewModel.customPreset.id
                ) {
                    viewModel.selectPreset(viewModel.customPreset)
                }

                if viewModel.searchResultsEmpty {
                    EmptySearchState()
                        .padding(.top, 8)
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var detailPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                presetHero
                configurationCard
                checklistCard
                actionsCard
                errorCard
            }
            .padding(18)
        }
    }

    private var presetHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.currentPreset.displayName)
                        .font(.system(size: 24, weight: .semibold))
                    Text(viewModel.presetSummary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Badge(text: viewModel.currentPreset.provider, isProminent: true)
                    Badge(text: viewModel.currentPreset.badgeText, isProminent: viewModel.currentPreset.isLatest)
                }
            }

            Text(viewModel.presetNotes)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                StatusPill(label: "Model", value: viewModel.modelID.isEmpty ? "Set a model" : viewModel.modelID)
                StatusPill(label: "Endpoint", value: viewModel.currentConnectionDetail)
                StatusPill(label: "Key", value: viewModel.savedKeyStatus)
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

    private var configurationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Configuration", subtitle: "Edit before applying if you need a custom endpoint")

            VStack(alignment: .leading, spacing: 12) {
                LabeledField(
                    label: "Model ID",
                    helpText: "Use the exact model name Claude Code should switch to.",
                    text: $viewModel.modelID,
                    placeholder: "claude-sonnet-4-6"
                )

                LabeledField(
                    label: "Endpoint or gateway URL",
                    helpText: viewModel.currentPreset.requiresGateway ? "Required for gateway-backed presets." : "Leave blank for direct Claude models.",
                    text: $viewModel.baseURL,
                    placeholder: "https://your-gateway.example.com/anthropic"
                )

                LabeledSecureField(
                    label: "API key or bearer token",
                    helpText: "Saved in Keychain so you do not need to retype it every time.",
                    text: $viewModel.apiKey,
                    placeholder: "Paste once, then save"
                )
            }

            HStack(spacing: 8) {
                Button(viewModel.isSavingKey ? "Saving..." : "Save Key") {
                    viewModel.saveKey()
                }
                .disabled(viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSavingKey)

                Button("Clear Saved Key") {
                    viewModel.clearSavedKey()
                }
                .disabled(viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()

                Text(viewModel.docsURL.absoluteString)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "What this preset writes", subtitle: "Quick confirmation before you apply")

            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.checklistRows) { row in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: row.isComplete ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(row.isComplete ? .green : .orange)
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.system(size: 12, weight: .semibold))
                            Text(row.value)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }

            Text("Claude Code will update `~/.claude/settings.json` and keep your saved key in Keychain.")
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

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Actions", subtitle: "Apply the selected preset or open the Claude files directly")

            HStack(spacing: 10) {
                Button {
                    viewModel.applySelection()
                } label: {
                    if viewModel.isApplying {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: 18, height: 18)
                    } else {
                        Text("Apply selected model")
                    }
                }
                .keyboardShortcut(.defaultAction)

                Button("Reveal settings file") { onRevealSettings() }
                Button("Open Claude folder") { onRevealFolder() }

                Spacer()
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

    private var errorCard: some View {
        Group {
            if let error = viewModel.lastErrorMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.orange.opacity(0.08))
                )
            }
        }
    }

    private func sectionSubtitle(for section: ModelSection) -> String {
        switch section {
        case .featured:
            return "Current best picks"
        case .official:
            return "Direct provider models"
        case .community:
            return "Gateway-backed community models"
        case .custom:
            return "Manual endpoint"
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
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

private struct StatusPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 11))
                .lineLimit(1)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct SearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            Text(helpText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct LabeledSecureField: View {
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
    }
}

private struct PresetRow: View {
    let preset: ModelPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(preset.displayName)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)

                        Text(preset.badgeText)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(Capsule())
                    }

                    Text(preset.provider)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    Text(preset.summary)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.55) : Color.primary.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(MenuSwitchRowButtonStyle())
    }
}

private struct EmptySearchState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No matching models")
                .font(.system(size: 12, weight: .semibold))
            Text("Clear the search field to see the full catalog, or try a provider name like DeepSeek, Kimi, or Qwen.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct MenuSwitchRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.82), value: configuration.isPressed)
    }
}
