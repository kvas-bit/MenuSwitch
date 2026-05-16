import Foundation
import Testing
@testable import MenuSwitch

@Suite("MenuSwitch package tests")
struct MenuSwitchTests {
    @Test("Preset catalog includes the requested providers and community models")
    func presetCatalogCoverage() {
        let ids = Set(PresetCatalog.presets.map(\.id))

        #expect(ids.contains("deepseek-v4-pro"))
        #expect(ids.contains("deepseek-v4-flash"))
        #expect(ids.contains("kimi-k2.6"))
        #expect(ids.contains("kimi-k2.5"))
        #expect(ids.contains("minimax-token-plan"))
        #expect(ids.contains("minimax-payg"))
        #expect(ids.contains("qwen3-coder"))
        #expect(ids.contains("llama-3.3-70b-instruct"))
        #expect(ids.contains("mistral-small-3.1"))
        #expect(ids.contains("glm-4.5"))
        #expect(PresetCatalog.presets.count == 10)
    }

    @Test("Claude settings round-trip in a temporary home directory")
    func settingsRoundTrip() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = ClaudeCodeSettingsStore(homeDirectory: tempRoot)
        guard let preset = PresetCatalog.preset(with: "deepseek-v4-pro") else {
            Issue.record("Missing DeepSeek preset")
            return
        }

        try store.apply(
            preset: preset,
            baseURL: preset.baseURL ?? "",
            modelID: preset.modelID,
            apiKey: "test-key"
        )

        let data = try Data(contentsOf: store.settingsFileURL)
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(root?["model"] as? String == "deepseek-v4-pro")

        let env = root?["env"] as? [String: Any]
        #expect(env?["ANTHROPIC_BASE_URL"] as? String == "https://api.deepseek.com/anthropic")
        #expect(env?["ANTHROPIC_MODEL"] as? String == "deepseek-v4-pro")
        #expect(env?["ANTHROPIC_AUTH_TOKEN"] as? String == "test-key")
    }
}
