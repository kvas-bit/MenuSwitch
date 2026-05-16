import Foundation

enum ModelSection: String, CaseIterable, Identifiable, Hashable {
    case featured = "Recommended"
    case official = "Official"
    case community = "Community"
    case custom = "Custom"

    var id: String { rawValue }
}

struct ModelPreset: Identifiable, Hashable {
    let id: String
    let section: ModelSection
    let provider: String
    let displayName: String
    let modelID: String
    let summary: String
    let notes: String
    let docsURL: URL
    let baseURL: String?
    let requiresGateway: Bool
    let isLatest: Bool
    let recommended: Bool
    let keychainAccount: String
    let extraEnvironment: [String: String]
    let aliasEnvironment: [String: String]
    let sortOrder: Int

    var idString: String { id }

    var badgeText: String {
        if isLatest {
            return "Latest"
        }
        if requiresGateway {
            return "Gateway"
        }
        return "Ready"
    }

    var sectionTitle: String {
        section.rawValue
    }

    var isCustom: Bool {
        section == .custom
    }

    static func custom(modelID: String = "", baseURL: String = "", notes: String = "Set any Anthropic-compatible endpoint and model here.", docsURL: URL = ModelCatalog.gatewayDocsURL) -> ModelPreset {
        ModelPreset(
            id: "custom",
            section: .custom,
            provider: "Custom",
            displayName: "Custom endpoint",
            modelID: modelID,
            summary: "Use any Anthropic-compatible proxy, gateway, or provider that Claude Code can reach.",
            notes: notes,
            docsURL: docsURL,
            baseURL: baseURL.isEmpty ? nil : baseURL,
            requiresGateway: true,
            isLatest: false,
            recommended: false,
            keychainAccount: "menu-switch-custom",
            extraEnvironment: [:],
            aliasEnvironment: [:],
            sortOrder: 999
        )
    }
}

enum ModelCatalog {
    static let claudeDocsURL = URL(string: "https://code.claude.com/docs/en/model-config.md")!
    static let gatewayDocsURL = URL(string: "https://code.claude.com/docs/en/llm-gateway.md")!
    static let deepseekDocsURL = URL(string: "https://api-docs.deepseek.com/quick_start/agent_integrations/claude_code")!
    static let kimiDocsURL = URL(string: "https://platform.kimi.ai/docs/guide/agent-support.md")!
    static let minimaxDocsURL = URL(string: "https://api.minimax.chat/docs")!
    static let qwenDocsURL = URL(string: "https://qwenlm.github.io/")!
    static let llamaDocsURL = URL(string: "https://www.llama.com/")!
    static let glmDocsURL = URL(string: "https://www.zhipuai.cn/")!
    static let mistralDocsURL = URL(string: "https://mistral.ai/models")!

    static let presets: [ModelPreset] = [
        ModelPreset(
            id: "claude-opus-4-7",
            section: .featured,
            provider: "Anthropic",
            displayName: "Claude Opus 4.7",
            modelID: "claude-opus-4-7",
            summary: "Latest reasoning model for the most demanding coding and architecture work.",
            notes: "Opus 4.7 is the current flagship model in Claude Code. Use it when you want the deepest reasoning and the strongest plan quality.",
            docsURL: claudeDocsURL,
            baseURL: nil,
            requiresGateway: false,
            isLatest: true,
            recommended: true,
            keychainAccount: "claude-opus-4-7",
            extraEnvironment: [:],
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-7",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-6",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "haiku"
            ],
            sortOrder: 10
        ),
        ModelPreset(
            id: "claude-sonnet-4-6",
            section: .featured,
            provider: "Anthropic",
            displayName: "Claude Sonnet 4.6",
            modelID: "claude-sonnet-4-6",
            summary: "Current daily driver for coding, refactors, and fast iteration.",
            notes: "Sonnet 4.6 is the balanced default for everyday coding in Claude Code.",
            docsURL: claudeDocsURL,
            baseURL: nil,
            requiresGateway: false,
            isLatest: true,
            recommended: true,
            keychainAccount: "claude-sonnet-4-6",
            extraEnvironment: [:],
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-7",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-6",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "haiku"
            ],
            sortOrder: 20
        ),
        ModelPreset(
            id: "claude-haiku",
            section: .official,
            provider: "Anthropic",
            displayName: "Claude Haiku",
            modelID: "haiku",
            summary: "Fastest Claude option for lightweight editing and background tasks.",
            notes: "Claude Code treats Haiku as the fast, efficient option. It resolves to the latest Haiku model for your account.",
            docsURL: claudeDocsURL,
            baseURL: nil,
            requiresGateway: false,
            isLatest: true,
            recommended: true,
            keychainAccount: "claude-haiku",
            extraEnvironment: [:],
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-7",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-6",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "haiku"
            ],
            sortOrder: 30
        ),
        ModelPreset(
            id: "deepseek-v4-pro",
            section: .featured,
            provider: "DeepSeek",
            displayName: "DeepSeek V4 Pro",
            modelID: "deepseek-v4-pro[1m]",
            summary: "Latest DeepSeek reasoning model exposed through an Anthropic-compatible endpoint.",
            notes: "DeepSeek documents Claude Code support through https://api.deepseek.com/anthropic. The current guide sets Opus and Sonnet aliases to deepseek-v4-pro[1m].",
            docsURL: deepseekDocsURL,
            baseURL: "https://api.deepseek.com/anthropic",
            requiresGateway: false,
            isLatest: true,
            recommended: true,
            keychainAccount: "deepseek-v4-pro",
            extraEnvironment: [
                "CLAUDE_CODE_EFFORT_LEVEL": "max",
                "CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-flash"
            ],
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-pro[1m]",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-pro[1m]",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash"
            ],
            sortOrder: 40
        ),
        ModelPreset(
            id: "deepseek-v4-flash",
            section: .official,
            provider: "DeepSeek",
            displayName: "DeepSeek V4 Flash",
            modelID: "deepseek-v4-flash",
            summary: "Lower-latency DeepSeek endpoint for quick edits and cheaper iterations.",
            notes: "Use the Anthropic-compatible DeepSeek endpoint for flash-speed responses. This is the fast companion model to V4 Pro.",
            docsURL: deepseekDocsURL,
            baseURL: "https://api.deepseek.com/anthropic",
            requiresGateway: false,
            isLatest: true,
            recommended: false,
            keychainAccount: "deepseek-v4-flash",
            extraEnvironment: [
                "CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-flash"
            ],
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-flash",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-flash",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash"
            ],
            sortOrder: 50
        ),
        ModelPreset(
            id: "kimi-k2-6",
            section: .featured,
            provider: "Moonshot",
            displayName: "Kimi K2.6",
            modelID: "kimi-k2.6",
            summary: "Latest Kimi model for agentic coding and long-context work.",
            notes: "Kimi's Claude Code guide uses https://api.moonshot.ai/anthropic with the kimi-k2.5 model. K2.6 is the current platform model and keeps the same Anthropic-compatible flow.",
            docsURL: kimiDocsURL,
            baseURL: "https://api.moonshot.ai/anthropic",
            requiresGateway: false,
            isLatest: true,
            recommended: true,
            keychainAccount: "kimi-k2-6",
            extraEnvironment: [
                "ENABLE_TOOL_SEARCH": "false"
            ],
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "kimi-k2.6",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "kimi-k2.6",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "kimi-k2.6"
            ],
            sortOrder: 60
        ),
        ModelPreset(
            id: "minimax-m2-7-token",
            section: .featured,
            provider: "MiniMax",
            displayName: "MiniMax M2.7 Token Plan",
            modelID: "minimax-m2.7",
            summary: "Current MiniMax token-plan entry for a gateway or proxy-backed Claude Code setup.",
            notes: "MiniMax's public docs highlight M2.7 and token-plan offerings. This preset is a gateway-friendly slot for an Anthropic-compatible proxy that routes to MiniMax.",
            docsURL: minimaxDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: true,
            keychainAccount: "minimax-m2-7-token",
            extraEnvironment: [:],
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "minimax-m2.7",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "minimax-m2.7",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "minimax-m2.7"
            ],
            sortOrder: 70
        ),
        ModelPreset(
            id: "minimax-m2-7-payg",
            section: .official,
            provider: "MiniMax",
            displayName: "MiniMax M2.7 Pay-by-Use",
            modelID: "minimax-m2.7",
            summary: "Pay-as-you-go MiniMax entry for the same M2.7 family.",
            notes: "Use this when you want the same M2.7 model family with per-use billing through a compatible gateway.",
            docsURL: minimaxDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: false,
            keychainAccount: "minimax-m2-7-payg",
            extraEnvironment: [:],
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "minimax-m2.7",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "minimax-m2.7",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "minimax-m2.7"
            ],
            sortOrder: 80
        ),
        ModelPreset(
            id: "qwen3-coder",
            section: .community,
            provider: "Qwen",
            displayName: "Qwen3 Coder",
            modelID: "qwen3-coder",
            summary: "Strong coding model for gateway-backed Claude Code setups.",
            notes: "Popular for code generation and agentic workflows. Pair it with an Anthropic-compatible gateway URL in this app.",
            docsURL: qwenDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: true,
            keychainAccount: "qwen3-coder",
            extraEnvironment: [:],
            aliasEnvironment: [:],
            sortOrder: 100
        ),
        ModelPreset(
            id: "qwen3-235b-a22b",
            section: .community,
            provider: "Qwen",
            displayName: "Qwen3 235B A22B",
            modelID: "qwen3-235b-a22b",
            summary: "Large MoE community model commonly routed through gateways.",
            notes: "A heavy-weight Qwen3 variant that is often used for broader reasoning and coding tasks when a gateway is available.",
            docsURL: qwenDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: false,
            keychainAccount: "qwen3-235b-a22b",
            extraEnvironment: [:],
            aliasEnvironment: [:],
            sortOrder: 110
        ),
        ModelPreset(
            id: "qwen3-32b",
            section: .community,
            provider: "Qwen",
            displayName: "Qwen3 32B",
            modelID: "qwen3-32b",
            summary: "Smaller Qwen3 model for faster gateway-backed turns.",
            notes: "A lighter Qwen3 option for lower-latency gateway deployments.",
            docsURL: qwenDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: false,
            keychainAccount: "qwen3-32b",
            extraEnvironment: [:],
            aliasEnvironment: [:],
            sortOrder: 120
        ),
        ModelPreset(
            id: "llama-4-maverick",
            section: .community,
            provider: "Meta",
            displayName: "Llama 4 Maverick",
            modelID: "llama-4-maverick",
            summary: "Popular open-weight assistant model for gateway routing.",
            notes: "Use a gateway that exposes an Anthropic-compatible API and point this preset at it.",
            docsURL: llamaDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: false,
            keychainAccount: "llama-4-maverick",
            extraEnvironment: [:],
            aliasEnvironment: [:],
            sortOrder: 130
        ),
        ModelPreset(
            id: "llama-4-scout",
            section: .community,
            provider: "Meta",
            displayName: "Llama 4 Scout",
            modelID: "llama-4-scout",
            summary: "Faster Llama 4 family option for community gateway setups.",
            notes: "A lighter Llama 4 model that fits smaller gateway deployments and quicker iteration loops.",
            docsURL: llamaDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: false,
            keychainAccount: "llama-4-scout",
            extraEnvironment: [:],
            aliasEnvironment: [:],
            sortOrder: 140
        ),
        ModelPreset(
            id: "deepseek-v3-2",
            section: .community,
            provider: "DeepSeek",
            displayName: "DeepSeek V3.2",
            modelID: "deepseek-v3.2",
            summary: "Popular community DeepSeek model for gateway routing.",
            notes: "A current DeepSeek community model that fits Anthropic-compatible proxy setups when you do not want the v4 family.",
            docsURL: deepseekDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: false,
            keychainAccount: "deepseek-v3-2",
            extraEnvironment: [:],
            aliasEnvironment: [:],
            sortOrder: 150
        ),
        ModelPreset(
            id: "deepseek-r1-0528",
            section: .community,
            provider: "DeepSeek",
            displayName: "DeepSeek R1 0528",
            modelID: "deepseek-r1-0528",
            summary: "Reasoning-heavy DeepSeek community model for gateways.",
            notes: "Use when you want a reasoning-first community model behind an Anthropic-compatible endpoint.",
            docsURL: deepseekDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: false,
            keychainAccount: "deepseek-r1-0528",
            extraEnvironment: [:],
            aliasEnvironment: [:],
            sortOrder: 160
        ),
        ModelPreset(
            id: "glm-4-5",
            section: .community,
            provider: "Zhipu AI",
            displayName: "GLM-4.5",
            modelID: "glm-4.5",
            summary: "Widely used community model with strong coding and reasoning coverage.",
            notes: "GLM models usually run through a gateway or provider proxy, which fits this app's custom endpoint flow.",
            docsURL: glmDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: false,
            keychainAccount: "glm-4-5",
            extraEnvironment: [:],
            aliasEnvironment: [:],
            sortOrder: 170
        ),
        ModelPreset(
            id: "mistral-small-3-2",
            section: .community,
            provider: "Mistral",
            displayName: "Mistral Small 3.2",
            modelID: "mistral-small-3.2",
            summary: "Fast, general-purpose community model for gateway deployments.",
            notes: "A strong small model for quick Claude Code iterations behind a compatible proxy.",
            docsURL: mistralDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: false,
            keychainAccount: "mistral-small-3-2",
            extraEnvironment: [:],
            aliasEnvironment: [:],
            sortOrder: 180
        ),
        ModelPreset(
            id: "mistral-medium-3-2",
            section: .community,
            provider: "Mistral",
            displayName: "Mistral Medium 3.2",
            modelID: "mistral-medium-3.2",
            summary: "Larger Mistral option for more demanding community gateway usage.",
            notes: "Use when you want more capability than Small 3.2 while keeping the same gateway pattern.",
            docsURL: mistralDocsURL,
            baseURL: nil,
            requiresGateway: true,
            isLatest: true,
            recommended: false,
            keychainAccount: "mistral-medium-3-2",
            extraEnvironment: [:],
            aliasEnvironment: [:],
            sortOrder: 190
        )
    ]

    static let customPreset = ModelPreset.custom()

    static let selectablePresets: [ModelPreset] = presets + [customPreset]

    static func filteredPresets(matching searchText: String) -> [ModelPreset] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return selectablePresets }

        return selectablePresets.filter { preset in
            [
                preset.provider,
                preset.displayName,
                preset.modelID,
                preset.summary,
                preset.notes,
                preset.sectionTitle
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(query)
        }
    }

    static func sectionedPresets(matching searchText: String) -> [(ModelSection, [ModelPreset])] {
        let filtered = filteredPresets(matching: searchText)
        return ModelSection.allCases.compactMap { section in
            guard section != .custom else { return nil }
            let rows = filtered.filter { $0.section == section }.sorted { $0.sortOrder < $1.sortOrder }
            guard !rows.isEmpty else { return nil }
            return (section, rows)
        }
    }

    static func recommendedPresets(matching searchText: String) -> [ModelPreset] {
        filteredPresets(matching: searchText)
            .filter { $0.recommended }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    static func matchingPreset(for configuration: ClaudeCodeConfiguration) -> ModelPreset? {
        selectablePresets.first { preset in
            normalize(preset.modelID) == normalize(configuration.model)
                && normalize(preset.baseURL) == normalize(configuration.baseURL)
        }
    }

    private static func normalize(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
    }
}
