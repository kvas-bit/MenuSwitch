import AppKit
import Foundation

struct ClaudeCodeConfiguration {
    let model: String?
    let baseURL: String?
    let hasAuthToken: Bool
}

struct ClaudeCodeSettingsStore {
    private let fileManager: FileManager
    private let homeDirectory: URL

    init(fileManager: FileManager = .default, homeDirectory: URL? = nil) {
        self.fileManager = fileManager
        self.homeDirectory = homeDirectory ?? fileManager.homeDirectoryForCurrentUser
    }

    var settingsDirectoryURL: URL {
        homeDirectory.appendingPathComponent(".claude", isDirectory: true)
    }

    var settingsFileURL: URL {
        settingsDirectoryURL.appendingPathComponent("settings.json")
    }

    func loadConfiguration() throws -> ClaudeCodeConfiguration {
        guard fileManager.fileExists(atPath: settingsFileURL.path) else {
            return ClaudeCodeConfiguration(model: nil, baseURL: nil, hasAuthToken: false)
        }

        let data = try Data(contentsOf: settingsFileURL)
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let model = root["model"] as? String
        let env = root["env"] as? [String: Any] ?? [:]
        let baseURL = env["ANTHROPIC_BASE_URL"] as? String
        let hasAuthToken = !(env["ANTHROPIC_AUTH_TOKEN"] as? String ?? "").isEmpty || !(env["ANTHROPIC_API_KEY"] as? String ?? "").isEmpty

        return ClaudeCodeConfiguration(model: model, baseURL: baseURL, hasAuthToken: hasAuthToken)
    }

    func apply(profile: MenuSwitchProfile, apiKey: String) throws {
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

        let trimmedModel = profile.modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBaseURL = profile.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedBaseURL.isEmpty {
            env["ANTHROPIC_BASE_URL"] = trimmedBaseURL
        }

        if !trimmedAPIKey.isEmpty {
            env["ANTHROPIC_AUTH_TOKEN"] = trimmedAPIKey
            env["ANTHROPIC_API_KEY"] = trimmedAPIKey
        }

        if !trimmedModel.isEmpty {
            env["ANTHROPIC_MODEL"] = trimmedModel
            root["model"] = trimmedModel
        } else {
            root.removeValue(forKey: "model")
        }
        profile.aliasEnvironment.forEach { key, value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { env[key] = trimmed }
        }
        profile.extraEnvironment.forEach { key, value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { env[key] = trimmed }
        }
        root["env"] = env

        let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: settingsFileURL, options: [.atomic])
    }

    func resetToClaudeDefaults() throws {
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
        root.removeValue(forKey: "model")
        root["env"] = env

        try fileManager.createDirectory(at: settingsDirectoryURL, withIntermediateDirectories: true)
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
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }
}
