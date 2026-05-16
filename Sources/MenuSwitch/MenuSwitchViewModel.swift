import Combine
import Foundation

struct MenuSwitchChecklistRow: Identifiable {
    let id: String
    let title: String
    let value: String
    let isComplete: Bool
}

@MainActor
final class MenuSwitchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedPresetID: String = ModelCatalog.customPreset.id
    @Published var modelID: String = ""
    @Published var baseURL: String = ""
    @Published var apiKey: String = ""
    @Published var statusText: String = "Choose a model, review the details, then apply it."
    @Published var lastErrorMessage: String?
    @Published var isApplying = false
    @Published var isSavingKey = false

    private let store: ClaudeCodeSettingsStore
    private var selectedPreset: ModelPreset = ModelCatalog.customPreset

    init(store: ClaudeCodeSettingsStore) {
        self.store = store
        refreshFromDisk()
    }

    var currentPreset: ModelPreset {
        selectedPreset
    }

    var currentConnectionSummary: String {
        if selectedPreset.isCustom {
            return "Custom endpoint"
        }
        return "\(selectedPreset.provider) · \(selectedPreset.displayName)"
    }

    var currentConnectionDetail: String {
        let endpoint = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if endpoint.isEmpty {
            return "No custom endpoint set"
        }
        return endpoint
    }

    var savedKeyStatus: String {
        if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No saved key loaded"
        }
        return "Key loaded for this preset"
    }

    var docsURL: URL {
        currentPreset.docsURL
    }

    var presetSummary: String {
        currentPreset.summary
    }

    var presetNotes: String {
        currentPreset.notes
    }

    var requiresGateway: Bool {
        currentPreset.requiresGateway
    }

    var recommendedPresets: [ModelPreset] {
        ModelCatalog.recommendedPresets(matching: searchText)
    }

    var sectionedPresets: [(ModelSection, [ModelPreset])] {
        ModelCatalog.sectionedPresets(matching: searchText)
    }

    var customPreset: ModelPreset {
        ModelCatalog.customPreset
    }

    var searchResultsEmpty: Bool {
        ModelCatalog.filteredPresets(matching: searchText).isEmpty
    }

    var checklistRows: [MenuSwitchChecklistRow] {
        [
            MenuSwitchChecklistRow(
                id: "model",
                title: "Model",
                value: modelID.isEmpty ? "Required" : modelID,
                isComplete: !modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ),
            MenuSwitchChecklistRow(
                id: "endpoint",
                title: "Endpoint",
                value: baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (requiresGateway ? "Required for this preset" : "Optional") : baseURL,
                isComplete: !requiresGateway || !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ),
            MenuSwitchChecklistRow(
                id: "key",
                title: "API key",
                value: savedKeyStatus,
                isComplete: !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ),
            MenuSwitchChecklistRow(
                id: "docs",
                title: "Docs",
                value: currentPreset.docsURL.absoluteString,
                isComplete: true
            )
        ]
    }

    func refreshFromDisk() {
        do {
            let configuration = try store.loadConfiguration()
            if let preset = ModelCatalog.matchingPreset(for: configuration) {
                loadPreset(preset)
                statusText = "Loaded \(preset.displayName) from \(store.settingsFileURL.lastPathComponent)."
            } else {
                loadCustom(modelID: configuration.model ?? "", baseURL: configuration.baseURL ?? "")
                statusText = "Loaded a custom Claude Code configuration."
            }
        } catch {
            loadCustom(modelID: "", baseURL: "")
            lastErrorMessage = error.localizedDescription
            statusText = "Ready to configure Claude Code."
        }
    }

    func loadPreset(_ preset: ModelPreset) {
        selectedPreset = preset
        selectedPresetID = preset.id
        modelID = preset.modelID
        baseURL = preset.baseURL ?? ""
        lastErrorMessage = nil
        statusText = "Selected \(preset.displayName)."

        apiKey = (try? KeychainVault.load(account: preset.keychainAccount)) ?? ""
    }

    func loadCustom(modelID: String, baseURL: String) {
        selectedPreset = ModelCatalog.customPreset
        selectedPresetID = ModelCatalog.customPreset.id
        self.modelID = modelID
        self.baseURL = baseURL
        lastErrorMessage = nil
        statusText = "Custom endpoint loaded."

        apiKey = (try? KeychainVault.load(account: ModelCatalog.customPreset.keychainAccount)) ?? ""
    }

    func selectPreset(_ preset: ModelPreset) {
        if preset.isCustom {
            loadCustom(modelID: modelID, baseURL: baseURL)
        } else {
            loadPreset(preset)
        }
    }

    func saveKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            lastErrorMessage = "Enter an API key first."
            return
        }

        do {
            isSavingKey = true
            defer { isSavingKey = false }
            try KeychainVault.save(trimmedKey, account: selectedPreset.keychainAccount)
            statusText = "Saved the key for \(selectedPreset.displayName)."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func clearSavedKey() {
        do {
            try KeychainVault.delete(account: selectedPreset.keychainAccount)
            apiKey = ""
            statusText = "Saved key cleared."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func applySelection() {
        let trimmedModel = modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedModel.isEmpty else {
            lastErrorMessage = "Model ID is required."
            return
        }

        if currentPreset.requiresGateway && trimmedBaseURL.isEmpty {
            lastErrorMessage = "This preset needs an endpoint or gateway URL."
            return
        }

        isApplying = true
        defer { isApplying = false }

        do {
            try store.apply(
                preset: currentPreset,
                modelID: trimmedModel,
                baseURL: trimmedBaseURL,
                apiKey: trimmedKey
            )

            if trimmedKey.isEmpty {
                try KeychainVault.delete(account: currentPreset.keychainAccount)
            } else {
                try KeychainVault.save(trimmedKey, account: currentPreset.keychainAccount)
            }

            statusText = "Applied \(trimmedModel) to Claude Code."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            statusText = "Could not update Claude Code."
        }
    }
}
