import Foundation
import Testing
@testable import MenuSwitch

@Suite("MenuSwitch package tests")
struct MenuSwitchTests {
    @Test("Template catalog includes the current provider models")
    func templateCatalogCoverage() {
        let ids = Set(ModelTemplateCatalog.templates.map(\.id))

        #expect(ids.contains("deepseek-v4-pro"))
        #expect(ids.contains("deepseek-v4-flash"))
        #expect(ids.contains("kimi-k2-6"))
        #expect(ids.contains("minimax-m2-7-token"))
        #expect(ids.contains("minimax-m2-7-payg"))
        #expect(ids.contains("qwen-3-6-plus"))
        #expect(ids.contains("glm-5-1"))
        #expect(ModelTemplateCatalog.templates.count == 7)
    }

    @Test("Settings store seeds enabled switch profiles")
    func settingsStoreSeedsProfiles() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = MenuSwitchSettingsStore(settingsDirectoryURL: tempRoot)
        let settings = try store.load()

        #expect(settings.profiles.count == 7)
        #expect(settings.profiles.filter(\.enabled).count == 2)
        #expect(settings.profiles.contains(where: { $0.id == "deepseek-v4-pro" }))
        #expect(settings.profiles.contains(where: { $0.id == "qwen-3-6-plus" }))
        #expect(settings.profiles.contains(where: { $0.id == "glm-5-1" }))
    }

    @Test("Claude settings round-trip from a profile")
    func settingsRoundTrip() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = ClaudeCodeSettingsStore(homeDirectory: tempRoot)
        guard let profile = ModelTemplateCatalog.seedProfiles().first(where: { $0.id == "deepseek-v4-pro" }) else {
            Issue.record("Missing DeepSeek profile")
            return
        }

        try store.apply(profile: profile, apiKey: "test-key")

        let data = try Data(contentsOf: store.settingsFileURL)
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(root?["model"] as? String == "deepseek-v4-pro[1m]")

        let env = root?["env"] as? [String: Any]
        #expect(env?["ANTHROPIC_DEFAULT_OPUS_MODEL"] as? String == "deepseek-v4-pro[1m]")
        #expect(env?["ANTHROPIC_DEFAULT_SONNET_MODEL"] as? String == "deepseek-v4-pro[1m]")
        #expect(env?["ANTHROPIC_DEFAULT_HAIKU_MODEL"] as? String == "deepseek-v4-flash")
        #expect(env?["ANTHROPIC_BASE_URL"] as? String == "https://api.deepseek.com/anthropic")
        #expect(env?["ANTHROPIC_AUTH_TOKEN"] as? String == "test-key")
    }
}
