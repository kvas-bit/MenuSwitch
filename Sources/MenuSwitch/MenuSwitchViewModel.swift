import Combine
import Foundation
import SwiftUI

enum MenuSwitchPage: String, CaseIterable, Identifiable {
    case switcher = "Switch"
    case settings = "Settings"

    var id: String { rawValue }
}

enum MenuSwitchEnvironmentScope: String, CaseIterable, Identifiable {
    case alias = "Claude aliases"
    case runtime = "Runtime overrides"

    var id: String { rawValue }
}

@MainActor
final class MenuSwitchViewModel: ObservableObject {
    @Published var page: MenuSwitchPage = .switcher
    @Published var settings: MenuSwitchAppSettings
    @Published var statusText: String
    @Published var lastErrorMessage: String?
    @Published var keyDrafts: [String: String] = [:]
    @Published var draggedProfileID: String?

    private let settingsStore: MenuSwitchSettingsStore
    private let claudeStore: ClaudeCodeSettingsStore

    init(settingsStore: MenuSwitchSettingsStore, claudeStore: ClaudeCodeSettingsStore) {
        self.settingsStore = settingsStore
        self.claudeStore = claudeStore

        let loaded = (try? settingsStore.load()) ?? MenuSwitchAppSettings(
            profiles: ModelTemplateCatalog.seedProfiles(),
            selectedProfileID: ModelTemplateCatalog.seedProfiles().first(where: { $0.enabled })?.id
        )

        var seeded = loaded
        if seeded.selectedProfileID == nil {
            seeded.selectedProfileID = seeded.profiles.first(where: { $0.enabled })?.id
        }

        settings = seeded
        statusText = seeded.selectedProfileID == nil ? "Add or enable a model in Settings." : "Ready to switch models."
        lastErrorMessage = nil
    }

    var enabledProfiles: [MenuSwitchProfile] {
        settings.profiles.filter(\.enabled).sorted { $0.sortOrder < $1.sortOrder }
    }

    var configuredProfiles: [MenuSwitchProfile] {
        settings.profiles.sorted { $0.sortOrder < $1.sortOrder }
    }

    var currentProfile: MenuSwitchProfile? {
        if let selected = settings.selectedProfileID,
           let profile = settings.profiles.first(where: { $0.id == selected }) {
            return profile
        }
        return enabledProfiles.first
    }

    var activeProfileLabel: String {
        currentProfile?.name ?? "No enabled models"
    }

    var activeProfileSubtitle: String {
        currentProfile.map { "\($0.provider) · \($0.modelID)" } ?? "Open Settings to configure a profile."
    }

    var switcherEmptyState: Bool {
        enabledProfiles.isEmpty
    }

    var settingsSummary: String {
        "\(settings.profiles.count) configured profiles"
    }

    func selectProfile(_ profile: MenuSwitchProfile) {
        settings.selectedProfileID = profile.id
        persistSettingsIfPossible()
        statusText = "Selected \(profile.name)."
        lastErrorMessage = nil
    }

    func apply(profile: MenuSwitchProfile) {
        do {
            try applyProfile(profile, saveSelection: true)
        } catch {
            lastErrorMessage = error.localizedDescription
            statusText = "Could not update Claude Code."
        }
    }

    func applySelectedProfile() {
        guard let profile = currentProfile else {
            lastErrorMessage = "Enable or configure a model first."
            return
        }
        apply(profile: profile)
    }

    func saveSettings() {
        do {
            try settingsStore.save(settings)
            statusText = "Settings saved."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func resetClaudeCodeSettings() {
        do {
            try claudeStore.resetToClaudeDefaults()
            statusText = "Restored Claude Code defaults."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func restoreDefaults() {
        do {
            settings = try settingsStore.resetToDefaults()
            keyDrafts.removeAll()
            statusText = "Restored default provider profiles."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func addProfile(from template: MenuSwitchTemplate) {
        let newProfile = MenuSwitchProfile(
            id: UUID().uuidString,
            name: "\(template.name) (copy)",
            provider: template.provider,
            modelID: template.modelID,
            endpoint: template.endpoint,
            notes: template.notes,
            docsURL: template.docsURL,
            enabled: true,
            requiresEndpoint: template.requiresEndpoint,
            templateID: nil,
            sortOrder: (settings.profiles.map(\.sortOrder).max() ?? 0) + 10,
            aliasEnvironment: template.aliasEnvironment,
            extraEnvironment: template.extraEnvironment
        )
        settings.profiles.append(newProfile)
        settings.selectedProfileID = newProfile.id
        persistSettingsIfPossible()
        statusText = "Added profile from \(template.name) template."
    }

    func addCustomProfile() {
        let newProfile = MenuSwitchProfile(
            id: UUID().uuidString,
            name: "Custom Model",
            provider: "Custom",
            modelID: "",
            endpoint: "",
            notes: "Paste any Anthropic-compatible model and endpoint here.",
            docsURL: "",
            enabled: true,
            requiresEndpoint: true,
            templateID: nil,
            sortOrder: (settings.profiles.map(\.sortOrder).max() ?? 0) + 10,
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": ""
            ],
            extraEnvironment: [
                "CLAUDE_CODE_SUBAGENT_MODEL": "",
                "CLAUDE_CODE_EFFORT_LEVEL": "",
                "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "",
                "ENABLE_TOOL_SEARCH": ""
            ]
        )
        settings.profiles.append(newProfile)
        settings.selectedProfileID = newProfile.id
        keyDrafts[newProfile.id] = ""
        persistSettingsIfPossible()
        statusText = "Added a custom profile."
    }

    func removeProfile(id: String) {
        guard settings.profiles.count > 1 else {
            lastErrorMessage = "Keep at least one profile configured."
            return
        }

        if let removed = settings.profiles.first(where: { $0.id == id }) {
            try? KeychainVault.delete(account: removed.keychainAccount)
        }

        settings.profiles.removeAll { $0.id == id }
        keyDrafts[id] = nil

        if settings.selectedProfileID == id {
            settings.selectedProfileID = settings.profiles.first(where: { $0.enabled })?.id ?? settings.profiles.first?.id
        }

        normalizeSortOrder()
        persistSettingsIfPossible()
        statusText = "Removed a profile."
        lastErrorMessage = nil
    }

    func moveProfile(from sourceID: String, before targetID: String) {
        guard sourceID != targetID,
              let sourceIndex = settings.profiles.firstIndex(where: { $0.id == sourceID }),
              let targetIndex = settings.profiles.firstIndex(where: { $0.id == targetID }) else {
            return
        }

        let profile = settings.profiles.remove(at: sourceIndex)
        var insertionIndex = targetIndex
        if sourceIndex < targetIndex {
            insertionIndex -= 1
        }
        insertionIndex = max(0, min(insertionIndex, settings.profiles.count))
        settings.profiles.insert(profile, at: insertionIndex)
        normalizeSortOrder()
        persistSettingsIfPossible()
        statusText = "Reordered profiles."
    }

    func setEnabled(_ enabled: Bool, for profileID: String) {
        updateProfile(id: profileID) { profile in
            profile.enabled = enabled
        }

        if !enabled, settings.selectedProfileID == profileID {
            settings.selectedProfileID = settings.profiles.first(where: { $0.enabled })?.id ?? settings.profiles.first?.id
        } else if enabled, settings.selectedProfileID == nil {
            settings.selectedProfileID = profileID
        }

        persistSettingsIfPossible()
        statusText = enabled ? "Enabled profile." : "Disabled profile."
    }

    func saveKey(for profileID: String, key: String) {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            lastErrorMessage = "Enter an API key first."
            return
        }

        guard let profile = settings.profiles.first(where: { $0.id == profileID }) else {
            lastErrorMessage = "Profile not found."
            return
        }

        do {
            try KeychainVault.save(trimmedKey, account: profile.keychainAccount)
            keyDrafts[profileID] = ""
            statusText = "Saved the key for \(profile.name)."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func clearKey(for profileID: String) {
        guard let profile = settings.profiles.first(where: { $0.id == profileID }) else {
            lastErrorMessage = "Profile not found."
            return
        }

        do {
            try KeychainVault.delete(account: profile.keychainAccount)
            keyDrafts[profileID] = ""
            statusText = "Cleared the saved key for \(profile.name)."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func hasStoredKey(for profileID: String) -> Bool {
        guard let profile = settings.profiles.first(where: { $0.id == profileID }) else {
            return false
        }
        return (try? KeychainVault.load(account: profile.keychainAccount)) != nil
    }

    func storedKeyStatus(for profileID: String) -> String {
        hasStoredKey(for: profileID) ? "Saved in Keychain" : "No saved key"
    }

    func keyBinding(for profileID: String) -> Binding<String> {
        Binding(
            get: { [weak self] in
                self?.keyDrafts[profileID, default: ""] ?? ""
            },
            set: { [weak self] newValue in
                self?.keyDrafts[profileID] = newValue
            }
        )
    }

    func profileBinding(for profileID: String) -> Binding<MenuSwitchProfile>? {
        guard let index = settings.profiles.firstIndex(where: { $0.id == profileID }) else {
            return nil
        }

        return Binding(
            get: {
                self.settings.profiles[index]
            },
            set: { newValue in
                self.settings.profiles[index] = newValue
            }
        )
    }

    func environmentBinding(profileID: String, key: String, scope: MenuSwitchEnvironmentScope) -> Binding<String> {
        Binding(
            get: {
                self.environmentValue(profileID: profileID, key: key, scope: scope)
            },
            set: { newValue in
                self.setEnvironmentValue(profileID: profileID, key: key, scope: scope, value: newValue)
            }
        )
    }

    func setEnvironmentValue(profileID: String, key: String, scope: MenuSwitchEnvironmentScope, value: String) {
        updateProfile(id: profileID) { profile in
            switch scope {
            case .alias:
                profile.aliasEnvironment[key] = value
            case .runtime:
                profile.extraEnvironment[key] = value
            }
        }
    }

    func canDelete(profileID: String) -> Bool {
        settings.profiles.count > 1 && settings.profiles.contains(where: { $0.id == profileID })
    }

    private func updateProfile(id: String, mutate: (inout MenuSwitchProfile) -> Void) {
        guard let index = settings.profiles.firstIndex(where: { $0.id == id }) else {
            return
        }
        mutate(&settings.profiles[index])
    }

    private func applyProfile(_ profile: MenuSwitchProfile, saveSelection: Bool) throws {
        let draftKey = keyDrafts[profile.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = draftKey.isEmpty ? ((try? KeychainVault.load(account: profile.keychainAccount)) ?? "") : draftKey

        if profile.requiresEndpoint && profile.endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SimpleError(message: "This profile needs an endpoint or gateway URL.")
        }

        try claudeStore.apply(profile: profile, apiKey: apiKey)

        if !draftKey.isEmpty {
            try? KeychainVault.save(draftKey, account: profile.keychainAccount)
            keyDrafts[profile.id] = ""
        }

        if saveSelection {
            settings.selectedProfileID = profile.id
            persistSettingsIfPossible()
        }

        statusText = "Applied \(profile.name) to Claude Code."
        lastErrorMessage = nil
    }

    private func persistSettingsIfPossible() {
        do {
            try settingsStore.save(settings)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func environmentValue(profileID: String, key: String, scope: MenuSwitchEnvironmentScope) -> String {
        guard let profile = settings.profiles.first(where: { $0.id == profileID }) else {
            return ""
        }

        switch scope {
        case .alias:
            return profile.aliasEnvironment[key] ?? ""
        case .runtime:
            return profile.extraEnvironment[key] ?? ""
        }
    }

    private func normalizeSortOrder() {
        for index in settings.profiles.indices {
            settings.profiles[index].sortOrder = (index + 1) * 10
        }
    }
}

private struct SimpleError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
