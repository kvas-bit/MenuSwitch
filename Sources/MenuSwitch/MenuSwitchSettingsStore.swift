import AppKit
import Foundation

struct MenuSwitchProfile: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var provider: String
    var modelID: String
    var endpoint: String
    var notes: String
    var docsURL: String
    var enabled: Bool
    var requiresEndpoint: Bool
    var templateID: String?
    var sortOrder: Int
    var aliasEnvironment: [String: String]
    var extraEnvironment: [String: String]

    var keychainAccount: String {
        "menuswitch.\(id)"
    }
}

struct MenuSwitchAppSettings: Codable {
    var profiles: [MenuSwitchProfile]
    var selectedProfileID: String?
}

struct MenuSwitchSettingsStore {
    private let fileManager: FileManager
    private let settingsDirectoryURL: URL

    init(fileManager: FileManager = .default, settingsDirectoryURL: URL? = nil) {
        self.fileManager = fileManager
        if let settingsDirectoryURL {
            self.settingsDirectoryURL = settingsDirectoryURL
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.homeDirectoryForCurrentUser
            self.settingsDirectoryURL = appSupport.appendingPathComponent("MenuSwitch", isDirectory: true)
        }
    }

    var settingsFileURL: URL {
        settingsDirectoryURL.appendingPathComponent("settings.json")
    }

    func load() throws -> MenuSwitchAppSettings {
        guard fileManager.fileExists(atPath: settingsFileURL.path) else {
            let defaults = ModelTemplateCatalog.seedProfiles()
            return MenuSwitchAppSettings(
                profiles: defaults,
                selectedProfileID: defaults.first(where: { $0.enabled })?.id
            )
        }

        let data = try Data(contentsOf: settingsFileURL)
        return try JSONDecoder().decode(MenuSwitchAppSettings.self, from: data)
    }

    func save(_ settings: MenuSwitchAppSettings) throws {
        try fileManager.createDirectory(at: settingsDirectoryURL, withIntermediateDirectories: true)
        let data = try JSONEncoder.prettyPrintedEncoder.encode(settings)
        try data.write(to: settingsFileURL, options: [.atomic])
    }

    func resetToDefaults() throws -> MenuSwitchAppSettings {
        let defaults = ModelTemplateCatalog.seedProfiles()
        let settings = MenuSwitchAppSettings(
            profiles: defaults,
            selectedProfileID: defaults.first(where: { $0.enabled })?.id
        )
        try save(settings)
        return settings
    }

    func revealSettingsFile() {
        NSWorkspace.shared.activateFileViewerSelecting([settingsFileURL])
    }
}

private extension JSONEncoder {
    static var prettyPrintedEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
