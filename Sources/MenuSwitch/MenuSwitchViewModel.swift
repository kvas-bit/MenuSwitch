import Combine
import Foundation
import SwiftUI

enum MenuSwitchPage: String, CaseIterable, Identifiable {
    case switcher = "Switch"
    case settings = "Settings"

    var id: String { rawValue }
}

@MainActor
final class MenuSwitchViewModel: ObservableObject {
    @Published var page: MenuSwitchPage = .switcher
    @Published var settings: MenuSwitchAppSettings
    @Published var statusText: String
    @Published var lastErrorMessage: String?
    @Published var keyDrafts: [String: String] = [:]

    private let settingsStore: MenuSwitchSettingsStore
    private let claudeStore: ClaudeCodeSettingsStore

    init(settingsStore: MenuSwitchSettingsStore, claudeStore: ClaudeCodeSettingsStore) {
        self.settingsStore = settingsStore
        self.claudeStore = claudeStore

        var loadedSettings = (try? settingsStore.load()) ?? MenuSwitchAppSettings(
            profiles: ModelTemplateCatalog.seedProfiles(),
            selectedProfileID: ModelTemplateCatalog.seedProfiles().first(where: { $0.enabled })?.id
        )
        if loadedSettings.selectedProfileID == nil {
            loadedSettings.selectedProfileID = loadedSettings.profiles.first(where: { $0.enabled })?.id
        }

        self.settings = loadedSettings
        self.statusText = loadedSettings.selectedProfileID == nil ? "Add or enable a model in Settings." : "Ready to switch models."
        self.lastErrorMessage = nil
        self.keyDrafts = [:]
    }

    var enabledProfiles: [MenuSwitchProfile] {
        settings.profiles
            .filter(\.enabled)
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var configuredProfiles: [MenuSwitchProfile] {
        settings.profiles.sorted { $0.sortOrder < $1.sortOrder }
    }

    var currentProfile: MenuSwitchProfile? {
        if let selected = settings.selectedProfileID,
           let match = settings.profiles.first(where: { $0.id == selected }) {
            return match
        }
        return enabledProfiles.first
    }

    var activeProfileLabel: String {
        currentProfile?.name ?? "No enabled models"
    }

    var activeProfileSubtitle: String {
        currentProfile.map { "\($0.provider) · \($0.modelID)" } ?? "Open Settings to configure a model."
    }

    var switcherEmptyState: Bool {
        enabledProfiles.isEmpty
    }

    var settingsSummary: String {
        "\(settings.profiles.count) configured models"
    }

    func selectProfile(_ profile: MenuSwitchProfile) {
        settings.selectedProfileID = profile.id
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

    func restoreDefaults() {
        do {
            settings = try settingsStore.resetToDefaults()
            keyDrafts.removeAll()
            statusText = "Restored default provider models."
            lastErrorMessage = nil
            if settings.selectedProfileID == nil {
                settings.selectedProfileID = enabledProfiles.first?.id
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func addCustomProfile() {
        let newProfile = MenuSwitchProfile(
            id: UUID().uuidString,
            name: "Custom Model",
            provider: "Custom",
            modelID: "",
            endpoint: "",
            notes: "Paste any Anthropic-compatible model and endpoint here.",
            docsURL: ModelTemplateCatalog.qwenDocsURL,
            enabled: true,
            requiresEndpoint: true,
            templateID: nil,
            sortOrder: (settings.profiles.map(\.sortOrder).max() ?? 0) + 10,
            aliasEnvironment: [:],
            extraEnvironment: [:]
        )
        settings.profiles.append(newProfile)
        settings.selectedProfileID = newProfile.id
        statusText = "Added a custom model."
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
            settings.selectedProfileID = enabledProfiles.first?.id ?? settings.profiles.first?.id
        }

        statusText = "Removed a profile."
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

    func storedKeyStatus(for profileID: String) -> String {
        hasStoredKey(for: profileID) ? "Saved in Keychain" : "No saved key"
    }

    private func applyProfile(_ profile: MenuSwitchProfile, saveSelection: Bool) throws {
        let draftKey = keyDrafts[profile.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = draftKey.isEmpty ? ((try? KeychainVault.load(account: profile.keychainAccount)) ?? "") : draftKey

        if profile.requiresEndpoint && profile.endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SimpleError(message: "This profile needs an endpoint or gateway URL.")
        }

        try claudeStore.apply(profile: profile, apiKey: apiKey)

        if !draftKey.isEmpty {
            try KeychainVault.save(draftKey, account: profile.keychainAccount)
            keyDrafts[profile.id] = ""
        }

        if saveSelection {
            settings.selectedProfileID = profile.id
            try settingsStore.save(settings)
        }

        statusText = "Applied \(profile.name) to Claude Code."
        lastErrorMessage = nil
    }
}

private struct SimpleError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
