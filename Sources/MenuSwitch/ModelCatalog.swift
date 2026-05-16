import Foundation

struct MenuSwitchTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let provider: String
    let modelID: String
    let endpoint: String
    let notes: String
    let docsURL: String
    let requiresEndpoint: Bool
    let enabledByDefault: Bool
    let sortOrder: Int
    let aliasEnvironment: [String: String]
    let extraEnvironment: [String: String]
}

enum ModelTemplateCatalog {
    static let deepseekDocsURL = "https://api-docs.deepseek.com/quick_start/agent_integrations/claude_code"
    static let kimiDocsURL = "https://platform.kimi.ai/docs/guide/agent-support.md"
    static let minimaxDocsURL = "https://platform.minimaxi.com/docs/api-reference/api-overview"

    static let templates: [MenuSwitchTemplate] = [
        MenuSwitchTemplate(
            id: "anthropic-claude",
            name: "Anthropic Claude",
            provider: "Anthropic",
            modelID: "",
            endpoint: "",
            notes: "Native Anthropic Claude via Claude Code's built-in configuration. Clears all third-party overrides.",
            docsURL: "https://docs.anthropic.com/en/api/getting-started",
            requiresEndpoint: false,
            enabledByDefault: true,
            sortOrder: 0,
            aliasEnvironment: [:],
            extraEnvironment: [:]
        ),
        MenuSwitchTemplate(
            id: "deepseek-v4-pro",
            name: "DeepSeek V4 Pro",
            provider: "DeepSeek",
            modelID: "deepseek-v4-pro[1m]",
            endpoint: "https://api.deepseek.com/anthropic",
            notes: "Latest DeepSeek reasoning model with the Anthropic-compatible Claude Code endpoint.",
            docsURL: deepseekDocsURL,
            requiresEndpoint: false,
            enabledByDefault: true,
            sortOrder: 10,
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-pro[1m]",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-pro[1m]",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash"
            ],
            extraEnvironment: [
                "CLAUDE_CODE_EFFORT_LEVEL": "max",
                "CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-flash"
            ]
        ),
        MenuSwitchTemplate(
            id: "deepseek-v4-flash",
            name: "DeepSeek V4 Flash",
            provider: "DeepSeek",
            modelID: "deepseek-v4-flash",
            endpoint: "https://api.deepseek.com/anthropic",
            notes: "Fast DeepSeek model for quick iterations and lower-latency switching.",
            docsURL: deepseekDocsURL,
            requiresEndpoint: false,
            enabledByDefault: false,
            sortOrder: 20,
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-flash",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-flash",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash"
            ],
            extraEnvironment: [
                "CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-flash"
            ]
        ),
        MenuSwitchTemplate(
            id: "kimi-k2-6",
            name: "Kimi K2.6",
            provider: "Moonshot",
            modelID: "kimi-k2.6",
            endpoint: "https://api.moonshot.ai/anthropic",
            notes: "Current Kimi model for long-context coding and agentic work.",
            docsURL: kimiDocsURL,
            requiresEndpoint: false,
            enabledByDefault: true,
            sortOrder: 30,
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "kimi-k2.6",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "kimi-k2.6",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "kimi-k2.6"
            ],
            extraEnvironment: [
                "ENABLE_TOOL_SEARCH": "false"
            ]
        ),
        MenuSwitchTemplate(
            id: "minimax-m2-7-token",
            name: "MiniMax M2.7 Token Plan",
            provider: "MiniMax",
            modelID: "MiniMax-M2.7",
            endpoint: "https://api.minimaxi.com/anthropic",
            notes: "Token-plan profile for MiniMax M2.7 with the Anthropic-compatible endpoint.",
            docsURL: "https://platform.minimaxi.com/docs/token-plan/quickstart",
            requiresEndpoint: false,
            enabledByDefault: false,
            sortOrder: 40,
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "MiniMax-M2.7",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "MiniMax-M2.7",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MiniMax-M2.7"
            ],
            extraEnvironment: [:]
        ),
        MenuSwitchTemplate(
            id: "minimax-m2-7-payg",
            name: "MiniMax M2.7 Pay-by-Use",
            provider: "MiniMax",
            modelID: "MiniMax-M2.7",
            endpoint: "https://api.minimaxi.com/anthropic",
            notes: "Pay-by-use profile for MiniMax M2.7 with the same Anthropic-compatible endpoint.",
            docsURL: minimaxDocsURL,
            requiresEndpoint: false,
            enabledByDefault: false,
            sortOrder: 50,
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "MiniMax-M2.7",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "MiniMax-M2.7",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MiniMax-M2.7"
            ],
            extraEnvironment: [:]
        )
    ]

    static func seedProfiles() -> [MenuSwitchProfile] {
        templates.map { template in
            MenuSwitchProfile(
                id: template.id,
                name: template.name,
                provider: template.provider,
                modelID: template.modelID,
                endpoint: template.endpoint,
                notes: template.notes,
                docsURL: template.docsURL,
                enabled: template.enabledByDefault,
                requiresEndpoint: template.requiresEndpoint,
                templateID: template.id,
                sortOrder: template.sortOrder,
                aliasEnvironment: template.aliasEnvironment,
                extraEnvironment: template.extraEnvironment
            )
        }
        .sorted { $0.sortOrder < $1.sortOrder }
    }

    static func template(for id: String) -> MenuSwitchTemplate? {
        templates.first { $0.id == id }
    }
}
