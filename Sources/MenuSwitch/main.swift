import AppKit
import Security
import SwiftUI

@main
struct MenuSwitchApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = MenuSwitchAppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class MenuSwitchAppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = ClaudeCodeSettingsStore()
    private lazy var viewModel = MenuSwitchViewModel(store: settingsStore)
    private let popover = NSPopover()
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 520, height: 760)
        popover.contentViewController = NSHostingController(
            rootView: MenuSwitchPopoverView(
                viewModel: viewModel,
                onQuit: { NSApp.terminate(nil) },
                onRevealSettings: { [weak self] in self?.revealSettingsFile() },
                onOpenProjectFolder: { [weak self] in self?.revealProjectFolder() }
            )
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "switch.2", accessibilityDescription: "MenuSwitch")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func revealSettingsFile() {
        settingsStore.revealSettingsFile()
    }

    private func revealProjectFolder() {
        settingsStore.revealClaudeFolder()
    }
}

struct MenuSwitchPopoverView: View {
    @ObservedObject var viewModel: MenuSwitchViewModel
    let onQuit: () -> Void
    let onRevealSettings: () -> Void
    let onOpenProjectFolder: () -> Void

    private let twoColumnLayout = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                presetGrid
                configurationForm
                checklistSection
                footer
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 520, height: 760)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MenuSwitch")
                .font(.system(size: 22, weight: .semibold))
            Text(viewModel.statusText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label(viewModel.currentConnectionSummary, systemImage: "bolt.horizontal.circle")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(.quaternary.opacity(0.6))
                    .clipShape(Capsule())

                if viewModel.hasStoredAuthToken {
                    Label("API key saved", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.green)
                } else {
                    Label("No API key saved", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var presetGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Presets")
                .font(.system(size: 13, weight: .semibold))

            LazyVGrid(columns: twoColumnLayout, alignment: .leading, spacing: 10) {
                ForEach(viewModel.presets) { preset in
                    Button {
                        viewModel.loadPreset(preset)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(preset.name)
                                .font(.system(size: 13, weight: .semibold))
                                .multilineTextAlignment(.leading)
                            Text(preset.subtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            Text(preset.badge)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(viewModel.selectedPresetID == preset.id ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedPresetID == preset.id ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var configurationForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active configuration")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 10) {
                LabeledField(label: "Base URL", placeholder: "https://api.deepseek.com/anthropic", text: $viewModel.baseURL)
                LabeledField(label: "Model", placeholder: "deepseek-v4-pro", text: $viewModel.modelID)
                LabeledSecureField(label: "API key", placeholder: "Stored securely in Keychain", text: $viewModel.apiKey)
            }

            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundStyle(.secondary)
                Text(viewModel.savedKeyStatus)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear Saved Key") {
                    viewModel.clearSavedKey()
                }
                .buttonStyle(.borderless)
                .disabled(!viewModel.hasStoredAuthToken)
            }

            Text(viewModel.selectedPresetNotes)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button {
                    viewModel.applySelection()
                } label: {
                    if viewModel.isApplying {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Apply to Claude Code")
                    }
                }
                .keyboardShortcut(.defaultAction)

                Button("Reveal Settings") { onRevealSettings() }
                Button("Open Folder") { onOpenProjectFolder() }
            }

            if let error = viewModel.lastErrorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Integration checklist")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.checklistItems) { item in
                    Button {
                        viewModel.loadChecklistItem(item)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: item.requiresGateway ? "circle.dashed" : "checkmark.circle.fill")
                                .foregroundStyle(item.requiresGateway ? .orange : .green)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(item.title)
                                        .font(.system(size: 12, weight: .semibold))
                                    Spacer()
                                    Text(item.provider)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                Text(item.subtitle)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(item.docsLabel)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Claude settings") { onRevealSettings() }
            Button("Quit") { onQuit() }
            Spacer()
            Link("Live docs", destination: viewModel.currentDocsURL)
                .font(.system(size: 12))
        }
    }
}

struct LabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct LabeledSecureField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            SecureField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

@MainActor
final class MenuSwitchViewModel: ObservableObject {
    @Published var selectedPresetID: String = ""
    @Published var baseURL: String = ""
    @Published var modelID: String = ""
    @Published var apiKey: String = ""
    @Published var statusText: String = "Select a preset to load Claude Code settings."
    @Published var lastErrorMessage: String?
    @Published var isApplying = false

    let presets = PresetCatalog.presets
    let checklistItems = PresetCatalog.checklistItems

    private let store: ClaudeCodeSettingsStore
    private var selectedPreset: ModelPreset?

    init(store: ClaudeCodeSettingsStore) {
        self.store = store
        refreshFromDisk()
    }

    var currentConnectionSummary: String {
        guard let selectedPreset else { return "Custom" }
        return "\(selectedPreset.provider) · \(selectedPreset.modelID)"
    }

    var currentDocsURL: URL {
        selectedPreset?.docsURL ?? PresetCatalog.defaultDocsURL
    }

    var selectedPresetNotes: String {
        selectedPreset?.notes ?? "Custom configuration. Use the form fields above to switch Claude Code to a provider or model."
    }

    var hasStoredAuthToken: Bool {
        !apiKey.isEmpty
    }

    var savedKeyStatus: String {
        hasStoredAuthToken ? "API key is saved locally for this provider." : "No saved API key yet. Enter one once and it will be reused."
    }

    func refreshFromDisk() {
        do {
            let configuration = try store.loadConfiguration()
            if let match = PresetCatalog.matchingPreset(for: configuration) {
                applyPreset(match, keepExistingKey: true)
                statusText = "Loaded \(match.name) from \(store.settingsFilePath.lastPathComponent)."
            } else {
                selectedPresetID = "custom"
                selectedPreset = nil
                baseURL = configuration.baseURL ?? ""
                modelID = configuration.model ?? ""
                apiKey = configuration.hasAuthToken ? (try KeychainVault.load(service: KeychainVault.serviceName, account: store.customKeychainAccount) ?? "") : ""
                statusText = "Loaded a custom Claude Code configuration."
            }
        } catch {
            selectedPresetID = "custom"
            selectedPreset = nil
            statusText = "Ready. Claude settings file not found yet."
            lastErrorMessage = error.localizedDescription
        }
    }

    func loadPreset(_ preset: ModelPreset) {
        applyPreset(preset, keepExistingKey: false)
        statusText = "Prepared \(preset.name)."
        lastErrorMessage = nil
    }

    func loadChecklistItem(_ item: IntegrationChecklistItem) {
        if let preset = PresetCatalog.preset(with: item.presetID) {
            loadPreset(preset)
        } else {
            selectedPresetID = item.presetID
            selectedPreset = nil
            baseURL = item.baseURL ?? ""
            modelID = item.modelID
            statusText = "Prepared checklist item \(item.title)."
        }
    }

    func applySelection() {
        guard !modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            lastErrorMessage = "Model is required."
            return
        }

        if selectedPreset?.requiresGateway == true, baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lastErrorMessage = "This preset needs an Anthropic-compatible gateway URL before it can be applied."
            return
        }

        isApplying = true
        defer { isApplying = false }

        do {
            let derivedPreset = selectedPreset ?? ModelPreset.custom(
                id: selectedPresetID.isEmpty ? "custom" : selectedPresetID,
                baseURL: baseURL,
                modelID: modelID,
                docsURL: currentDocsURL
            )
            try store.apply(
                preset: derivedPreset,
                baseURL: baseURL,
                modelID: modelID,
                apiKey: apiKey
            )

            let account = selectedPreset?.keychainAccount ?? store.customKeychainAccount
            if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try KeychainVault.delete(service: KeychainVault.serviceName, account: account)
            } else {
                try KeychainVault.save(apiKey, service: KeychainVault.serviceName, account: account)
            }

            statusText = "Applied \(modelID) to Claude Code."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            statusText = "Could not apply the selected configuration."
        }
    }

    func clearSavedKey() {
        apiKey = ""
        do {
            try KeychainVault.delete(service: KeychainVault.serviceName, account: selectedPreset?.keychainAccount ?? store.customKeychainAccount)
            statusText = "Saved API key removed."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func applyPreset(_ preset: ModelPreset, keepExistingKey: Bool) {
        selectedPresetID = preset.id
        selectedPreset = preset
        baseURL = preset.baseURL ?? ""
        modelID = preset.modelID
        if !keepExistingKey {
            apiKey = (try? KeychainVault.load(service: KeychainVault.serviceName, account: preset.keychainAccount)) ?? ""
        }
    }
}

struct ModelPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let provider: String
    let subtitle: String
    let modelID: String
    let baseURL: String?
    let docsURL: URL
    let notes: String
    let extraEnvironment: [String: String]
    let keychainAccount: String
    let requiresGateway: Bool

    var badge: String {
        requiresGateway ? "Gateway/custom" : "Direct Anthropic-compatible"
    }

    static func custom(id: String, baseURL: String, modelID: String, docsURL: URL) -> ModelPreset {
        ModelPreset(
            id: id,
            name: "Custom",
            provider: "Custom",
            subtitle: "User-defined Anthropic-compatible endpoint",
            modelID: modelID,
            baseURL: baseURL.isEmpty ? nil : baseURL,
            docsURL: docsURL,
            notes: "Custom endpoint. Claude Code supports Anthropic-compatible gateways, so this form lets you point at any compatible proxy or provider.",
            extraEnvironment: [:],
            keychainAccount: "custom",
            requiresGateway: true
        )
    }
}

struct IntegrationChecklistItem: Identifiable, Hashable {
    let id: String
    let title: String
    let provider: String
    let subtitle: String
    let modelID: String
    let baseURL: String?
    let docsURL: URL
    let docsLabel: String
    let presetID: String
    let requiresGateway: Bool
}

enum PresetCatalog {
    static let defaultDocsURL = URL(string: "https://code.claude.com/docs/en/llm-gateway.md")!

    static let presets: [ModelPreset] = [
        ModelPreset(
            id: "deepseek-v4-pro",
            name: "DeepSeek V4 Pro",
            provider: "DeepSeek",
            subtitle: "Official Anthropic-compatible DeepSeek endpoint",
            modelID: "deepseek-v4-pro",
            baseURL: "https://api.deepseek.com/anthropic",
            docsURL: URL(string: "https://api-docs.deepseek.com/quick_start/agent_integrations/claude_code")!,
            notes: "DeepSeek documents this as an Anthropic-compatible Claude Code setup. Set your API key and keep the model pinned to deepseek-v4-pro.",
            extraEnvironment: [
                "CLAUDE_CODE_EFFORT_LEVEL": "max",
                "CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-flash"
            ],
            keychainAccount: "deepseek-v4-pro",
            requiresGateway: false
        ),
        ModelPreset(
            id: "deepseek-v4-flash",
            name: "DeepSeek V4 Flash",
            provider: "DeepSeek",
            subtitle: "Fast DeepSeek Anthropic-compatible endpoint",
            modelID: "deepseek-v4-flash",
            baseURL: "https://api.deepseek.com/anthropic",
            docsURL: URL(string: "https://api-docs.deepseek.com/")!,
            notes: "Use this when you want lower-latency DeepSeek behavior without leaving Claude Code's Anthropic-compatible flow.",
            extraEnvironment: [:],
            keychainAccount: "deepseek-v4-flash",
            requiresGateway: false
        ),
        ModelPreset(
            id: "kimi-k2.6",
            name: "Kimi K2.6",
            provider: "Moonshot",
            subtitle: "Kimi's latest agentic model",
            modelID: "kimi-k2.6",
            baseURL: "https://api.moonshot.ai/anthropic",
            docsURL: URL(string: "https://platform.kimi.ai/docs/guide/kimi-k2-6-quickstart.md")!,
            notes: "Kimi documents Claude Code usage with an Anthropic-compatible base URL and an API token from the Kimi console.",
            extraEnvironment: [
                "ENABLE_TOOL_SEARCH": "false"
            ],
            keychainAccount: "kimi-k2.6",
            requiresGateway: false
        ),
        ModelPreset(
            id: "kimi-k2.5",
            name: "Kimi K2.5",
            provider: "Moonshot",
            subtitle: "Claude Code guide in Kimi docs",
            modelID: "kimi-k2.5",
            baseURL: "https://api.moonshot.ai/anthropic",
            docsURL: URL(string: "https://platform.kimi.ai/docs/guide/agent-support.md")!,
            notes: "Kimi's Claude Code guide recommends the Moonshot Anthropic endpoint, your Kimi API key, and the kimi-k2.5 model alias.",
            extraEnvironment: [
                "ENABLE_TOOL_SEARCH": "false"
            ],
            keychainAccount: "kimi-k2.5",
            requiresGateway: false
        ),
        ModelPreset(
            id: "minimax-token-plan",
            name: "MiniMax Token Plan",
            provider: "MiniMax",
            subtitle: "Token-plan family entry for gateway/custom use",
            modelID: "minimax-m2.7",
            baseURL: nil,
            docsURL: URL(string: "https://api.minimax.chat/docs")!,
            notes: "MiniMax currently exposes standard API docs rather than an Anthropic-compatible Claude Code endpoint, so this preset is set up as a gateway/custom entry.",
            extraEnvironment: [:],
            keychainAccount: "minimax-token-plan",
            requiresGateway: true
        ),
        ModelPreset(
            id: "minimax-payg",
            name: "MiniMax Pay-by-Use",
            provider: "MiniMax",
            subtitle: "Pay-as-you-go family entry for gateway/custom use",
            modelID: "minimax-m2.7",
            baseURL: nil,
            docsURL: URL(string: "https://api.minimax.chat/docs")!,
            notes: "MiniMax pay-by-use integration is exposed as a custom/gateway flow in this app, with the model field ready for an Anthropic-compatible proxy.",
            extraEnvironment: [:],
            keychainAccount: "minimax-payg",
            requiresGateway: true
        ),
        ModelPreset(
            id: "qwen3-coder",
            name: "Qwen3 Coder",
            provider: "Qwen",
            subtitle: "Popular coding model via gateway",
            modelID: "qwen3-coder",
            baseURL: nil,
            docsURL: URL(string: "https://qwenlm.github.io/")!,
            notes: "Qwen models are generally routed through an Anthropic-compatible gateway for Claude Code. Fill in your gateway URL and API key, then keep the model identifier here.",
            extraEnvironment: [:],
            keychainAccount: "qwen3-coder",
            requiresGateway: true
        ),
        ModelPreset(
            id: "llama-3.3-70b-instruct",
            name: "Llama 3.3 70B",
            provider: "Meta",
            subtitle: "Popular open-weight instruction model",
            modelID: "llama-3.3-70b-instruct",
            baseURL: nil,
            docsURL: URL(string: "https://huggingface.co/meta-llama")!,
            notes: "Use an Anthropic-compatible gateway to route Claude Code to Llama 3.3. This preset only seeds the model name.",
            extraEnvironment: [:],
            keychainAccount: "llama-3.3-70b-instruct",
            requiresGateway: true
        ),
        ModelPreset(
            id: "mistral-small-3.1",
            name: "Mistral Small 3.1",
            provider: "Mistral",
            subtitle: "Fast open community model",
            modelID: "mistral-small-3.1",
            baseURL: nil,
            docsURL: URL(string: "https://mistral.ai/news/")!,
            notes: "This preset is a gateway-friendly community model entry. Fill in your Anthropic-compatible proxy or gateway endpoint before applying.",
            extraEnvironment: [:],
            keychainAccount: "mistral-small-3.1",
            requiresGateway: true
        ),
        ModelPreset(
            id: "glm-4.5",
            name: "GLM-4.5",
            provider: "Zhipu AI",
            subtitle: "Popular community reasoning/coding model",
            modelID: "glm-4.5",
            baseURL: nil,
            docsURL: URL(string: "https://www.zhipuai.cn/")!,
            notes: "Claude Code can reach GLM through an Anthropic-compatible gateway. This preset keeps the model name ready for that setup.",
            extraEnvironment: [:],
            keychainAccount: "glm-4.5",
            requiresGateway: true
        )
    ]

    static let checklistItems: [IntegrationChecklistItem] = presets.map { preset in
        IntegrationChecklistItem(
            id: preset.id,
            title: preset.name,
            provider: preset.provider,
            subtitle: preset.subtitle,
            modelID: preset.modelID,
            baseURL: preset.baseURL,
            docsURL: preset.docsURL,
            docsLabel: preset.docsURL.absoluteString,
            presetID: preset.id,
            requiresGateway: preset.requiresGateway
        )
    }

    static func preset(with id: String) -> ModelPreset? {
        presets.first { $0.id == id }
    }

    static func matchingPreset(for configuration: ClaudeCodeConfiguration) -> ModelPreset? {
        presets.first { preset in
            preset.modelID == configuration.model && normalizeBaseURL(preset.baseURL) == normalizeBaseURL(configuration.baseURL)
        }
    }

    private static func normalizeBaseURL(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
    }
}

struct ClaudeCodeConfiguration {
    let model: String?
    let baseURL: String?
    let hasAuthToken: Bool
}

struct ClaudeCodeSettingsStore {
    private let fileManager = FileManager.default
    let customKeychainAccount = "menu-switch-custom"

    var settingsDirectoryURL: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".claude", isDirectory: true)
    }

    var settingsFileURL: URL {
        settingsDirectoryURL.appendingPathComponent("settings.json")
    }

    var settingsFilePath: URL { settingsFileURL }

    func loadConfiguration() throws -> ClaudeCodeConfiguration {
        guard fileManager.fileExists(atPath: settingsFileURL.path) else {
            return ClaudeCodeConfiguration(model: nil, baseURL: nil, hasAuthToken: false)
        }

        let data = try Data(contentsOf: settingsFileURL)
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let model = root["model"] as? String
        let env = root["env"] as? [String: Any] ?? [:]
        let baseURL = env["ANTHROPIC_BASE_URL"] as? String
        let hasAuthToken = (env["ANTHROPIC_AUTH_TOKEN"] as? String)?.isEmpty == false || (env["ANTHROPIC_API_KEY"] as? String)?.isEmpty == false
        return ClaudeCodeConfiguration(model: model, baseURL: baseURL, hasAuthToken: hasAuthToken)
    }

    func apply(preset: ModelPreset, baseURL: String, modelID: String, apiKey: String) throws {
        try fileManager.createDirectory(at: settingsDirectoryURL, withIntermediateDirectories: true)

        var root = try loadRootDictionary()
        var env = root["env"] as? [String: Any] ?? [:]

        let managedKeys = [
            "ANTHROPIC_BASE_URL",
            "ANTHROPIC_AUTH_TOKEN",
            "ANTHROPIC_API_KEY",
            "ANTHROPIC_MODEL",
            "ANTHROPIC_DEFAULT_OPUS_MODEL",
            "ANTHROPIC_DEFAULT_SONNET_MODEL",
            "ANTHROPIC_DEFAULT_HAIKU_MODEL",
            "CLAUDE_CODE_SUBAGENT_MODEL",
            "CLAUDE_CODE_EFFORT_LEVEL",
            "ENABLE_TOOL_SEARCH",
            "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY"
        ]
        managedKeys.forEach { env.removeValue(forKey: $0) }

        if !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            env["ANTHROPIC_BASE_URL"] = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            env["ANTHROPIC_AUTH_TOKEN"] = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        env["ANTHROPIC_MODEL"] = modelID
        env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = modelID
        env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = modelID
        env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = modelID
        env["CLAUDE_CODE_SUBAGENT_MODEL"] = preset.extraEnvironment["CLAUDE_CODE_SUBAGENT_MODEL"] ?? modelID
        preset.extraEnvironment.forEach { env[$0.key] = $0.value }

        root["model"] = modelID
        root["env"] = env

        let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: settingsFileURL, options: [.atomic])
    }

    func revealSettingsFile() {
        NSWorkspace.shared.activateFileViewerSelecting([settingsFileURL])
    }

    func revealClaudeFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([settingsDirectoryURL])
    }

    private func loadRootDictionary() throws -> [String: Any] {
        guard fileManager.fileExists(atPath: settingsFileURL.path) else {
            return [:]
        }

        let data = try Data(contentsOf: settingsFileURL)
        return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }
}

enum KeychainVault {
    static let serviceName = "MenuSwitch"

    static func save(_ value: String, service: String, account: String) throws {
        try delete(service: service, account: account)

        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidEncoding
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.osStatus(status) }
    }

    static func load(service: String, account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError.osStatus(status) }

        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound { return }
        guard status == errSecSuccess else { throw KeychainError.osStatus(status) }
    }
}

enum KeychainError: LocalizedError {
    case invalidEncoding
    case osStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "Could not encode the API key."
        case .osStatus(let status):
            return "Keychain error: \(status)"
        }
    }
}
