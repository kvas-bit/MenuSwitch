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
    static let minimaxDocsURL = "https://api.minimax.chat/docs"
    static let qwenDocsURL = "https://qwenlm.github.io/"
    static let glmDocsURL = "https://www.zhipuai.cn/"

    static let templates: [MenuSwitchTemplate] = [
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
            modelID: "minimax-m2.7",
            endpoint: "",
            notes: "Token-plan slot for MiniMax M2.7 behind a compatible gateway.",
            docsURL: minimaxDocsURL,
            requiresEndpoint: true,
            enabledByDefault: false,
            sortOrder: 40,
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "minimax-m2.7",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "minimax-m2.7",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "minimax-m2.7"
            ],
            extraEnvironment: [:]
        ),
        MenuSwitchTemplate(
            id: "minimax-m2-7-payg",
            name: "MiniMax M2.7 Pay-by-Use",
            provider: "MiniMax",
            modelID: "minimax-m2.7",
            endpoint: "",
            notes: "Pay-by-use slot for MiniMax M2.7 through your preferred gateway or proxy.",
            docsURL: minimaxDocsURL,
            requiresEndpoint: true,
            enabledByDefault: false,
            sortOrder: 50,
            aliasEnvironment: [
                "ANTHROPIC_DEFAULT_OPUS_MODEL": "minimax-m2.7",
                "ANTHROPIC_DEFAULT_SONNET_MODEL": "minimax-m2.7",
                "ANTHROPIC_DEFAULT_HAIKU_MODEL": "minimax-m2.7"
            ],
            extraEnvironment: [:]
        ),
        MenuSwitchTemplate(
            id: "qwen-3-6-plus",
            name: "Qwen 3.6 Plus",
            provider: "Qwen",
            modelID: "qwen3.6-plus",
            endpoint: "",
            notes: "Current Qwen family model for gateway-backed Claude Code setups.",
            docsURL: qwenDocsURL,
            requiresEndpoint: true,
            enabledByDefault: false,
            sortOrder: 60,
            aliasEnvironment: [:],
            extraEnvironment: [:]
        ),
        MenuSwitchTemplate(
            id: "glm-5-1",
            name: "GLM 5.1",
            provider: "Zhipu AI",
            modelID: "glm-5.1",
            endpoint: "",
            notes: "Current GLM model for gateway-backed switching and full endpoint control.",
            docsURL: glmDocsURL,
            requiresEndpoint: true,
            enabledByDefault: false,
            sortOrder: 70,
            aliasEnvironment: [:],
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
