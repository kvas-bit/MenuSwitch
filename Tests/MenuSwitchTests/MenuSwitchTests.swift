import Foundation
import Testing
@testable import MenuSwitch

@Suite("MenuSwitch package tests")
struct MenuSwitchTests {
    @Test("Preset catalog includes the current latest models")
    func presetCatalogCoverage() {
        let ids = Set(ModelCatalog.presets.map(\.id))

        #expect(ids.contains("claude-opus-4-7"))
        #expect(ids.contains("claude-sonnet-4-6"))
        #expect(ids.contains("claude-haiku"))
        #expect(ids.contains("deepseek-v4-pro"))
        #expect(ids.contains("deepseek-v4-flash"))
        #expect(ids.contains("kimi-k2-6"))
        #expect(ids.contains("minimax-m2-7-token"))
        #expect(ids.contains("minimax-m2-7-payg"))
        #expect(ids.contains("qwen3-coder"))
        #expect(ids.contains("qwen3-235b-a22b"))
        #expect(ids.contains("qwen3-32b"))
        #expect(ids.contains("llama-4-maverick"))
        #expect(ids.contains("llama-4-scout"))
        #expect(ids.contains("deepseek-v3-2"))
        #expect(ids.contains("deepseek-r1-0528"))
        #expect(ids.contains("glm-4-5"))
        #expect(ids.contains("mistral-small-3-2"))
        #expect(ids.contains("mistral-medium-3-2"))
        #expect(ModelCatalog.presets.count == 18)
    }

    @Test("Search filtering matches providers and models")
    func searchFiltering() {
        let qwenRows = ModelCatalog.filteredPresets(matching: "qwen")
        #expect(qwenRows.count == 3)
        #expect(qwenRows.allSatisfy { $0.provider == "Qwen" })

        let maverickRows = ModelCatalog.filteredPresets(matching: "maverick")
        #expect(maverickRows.count == 1)
        #expect(maverickRows.first?.id == "llama-4-maverick")
    }

    @Test("Claude settings round-trip in a temporary home directory")
    func settingsRoundTrip() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = ClaudeCodeSettingsStore(homeDirectory: tempRoot)
        guard let preset = ModelCatalog.presets.first(where: { $0.id == "claude-opus-4-7" }) else {
            Issue.record("Missing Opus preset")
            return
        }

        try store.apply(
            preset: preset,
            modelID: preset.modelID,
            baseURL: preset.baseURL ?? "",
            apiKey: "test-key"
        )

        let data = try Data(contentsOf: store.settingsFileURL)
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(root?["model"] as? String == "claude-opus-4-7")

        let env = root?["env"] as? [String: Any]
        #expect(env?["ANTHROPIC_DEFAULT_OPUS_MODEL"] as? String == "claude-opus-4-7")
        #expect(env?["ANTHROPIC_DEFAULT_SONNET_MODEL"] as? String == "claude-sonnet-4-6")
        #expect(env?["ANTHROPIC_MODEL"] as? String == "claude-opus-4-7")
        #expect(env?["ANTHROPIC_AUTH_TOKEN"] as? String == "test-key")
    }
}
