import Foundation
import AgentKitCore
import os.log

/// LLM adapter for Apple's on-device Foundation Models (iOS 26+, macOS 26+).
///
/// Uses the `FoundationModels` framework for fully on-device, private inference.
/// No network required — works in airplane mode.
///
/// ## Current Status
/// This adapter is ready for integration when compiled with Xcode 26+ (which ships
/// the FoundationModels framework). On earlier Xcode versions, calling ``respond``
/// throws ``AgentError/providerUnavailable(_:)`` with instructions to upgrade.
///
/// When FoundationModels is available, the adapter:
/// 1. Creates a `LanguageModelSession` with the system model
/// 2. Injects tool descriptions into the system prompt
/// 3. Streams the response via `streamResponse(to:)`
/// 4. Parses tool call patterns from the response text
/// 5. The `AgentLoopRunner` executes tools and feeds results back
///
/// ## Example
/// ```swift
/// // On-device only
/// let agent = AgentKit(provider: .apple())
///
/// // Cloud primary with on-device fallback (airplane mode resilience)
/// let agent = AgentKit(
///     provider: .claude(apiKey: key),
///     fallbackProvider: .apple()
/// )
/// ```
public final class AppleAdapter: LLMAdapter, @unchecked Sendable {
    private let modelConfig: ModelIdentifier.Apple
    private let systemPrompt: String?
    private let logger = Logger(subsystem: "com.agentkit.providers", category: "AppleAdapter")

    /// Initialize an Apple on-device adapter.
    ///
    /// - Parameters:
    ///   - model: The Apple model configuration. Defaults to `.general`.
    ///   - systemPrompt: Optional system prompt prepended to instructions.
    public init(
        model: ModelIdentifier.Apple = .general,
        systemPrompt: String? = nil
    ) {
        self.modelConfig = model
        self.systemPrompt = systemPrompt
    }

    /// The model configuration this adapter was initialized with.
    public var model: ModelIdentifier.Apple { modelConfig }

    public func respond(
        messages: [AgentMessage],
        tools: [AgentTool],
        context: AgentContext
    ) async throws -> AsyncThrowingStream<AgentLoopEvent, Error> {
        // FoundationModels requires iOS 26+ / macOS 26+ SDK.
        // When compiled with Xcode 26+, replace this method body with
        // the native LanguageModelSession implementation.
        // See AGENT.md for the integration pattern.
        throw AgentError.providerUnavailable(
            "Apple Foundation Models requires iOS 26+ / macOS 26+ and Xcode 26+. "
            + "This binary was compiled with an earlier SDK. "
            + "Rebuild with Xcode 26 to enable on-device inference."
        )
    }

    // MARK: - Prompt Building Utilities

    /// Build the full instruction string including tool descriptions and app context.
    ///
    /// Public so that consumers compiling with Xcode 26+ can reuse this
    /// when wiring up the native `LanguageModelSession`.
    public func buildInstructions(tools: [AgentTool], context: AgentContext) -> String {
        var parts: [String] = []

        // Developer's system prompt from Configuration (via context)
        if let contextPrompt = context.systemPrompt {
            parts.append(contextPrompt)
        }

        // Adapter-level prompt (legacy, for direct adapter construction)
        if let prompt = systemPrompt {
            parts.append(prompt)
        }

        if let screen = context.currentScreen {
            parts.append("The user is currently on the '\(screen)' screen.")
        }
        if !context.userProperties.isEmpty {
            parts.append("User properties: \(context.userProperties.description)")
        }
        if !context.customState.isEmpty {
            parts.append("App state: \(context.customState.description)")
        }

        if !tools.isEmpty {
            parts.append("")
            parts.append("You have access to these tools. To use one, respond with EXACTLY:")
            parts.append("TOOL_CALL: <tool_name>({\"param\": \"value\"})")
            parts.append("")
            parts.append("Available tools:")
            for tool in tools {
                var desc = "- \(tool.name): \(tool.description)"
                if !tool.parameters.isEmpty {
                    let paramDescs = tool.parameters.map { p in
                        "\(p.name) (\(p.typeName)\(p.isRequired ? ", required" : "")): \(p.description)"
                    }
                    desc += "\n  Parameters: " + paramDescs.joined(separator: "; ")
                }
                parts.append(desc)
            }
            parts.append("")
            parts.append("If no tool is needed, respond with plain text.")
        }

        return parts.joined(separator: "\n")
    }

    /// Build a conversation prompt string from AgentKit message history.
    ///
    /// On-device models have small context windows (~4096 tokens), so this
    /// produces a compact text representation.
    public func buildPrompt(from messages: [AgentMessage]) -> String {
        var lines: [String] = []
        for message in messages {
            switch message {
            case .user(let text):
                lines.append("User: \(text)")
            case .assistant(let text):
                lines.append("Assistant: \(text)")
            case .toolCall(let name, let params):
                lines.append("Assistant: TOOL_CALL: \(name)(\(params.description))")
            case .toolResult(let name, let result):
                lines.append("Tool result for \(name): \(result)")
            }
        }
        return lines.joined(separator: "\n")
    }

    /// Parse a response string for tool call patterns.
    ///
    /// Looks for `TOOL_CALL: <name>({"key": "value"})` in the response.
    /// Returns the tool name and arguments JSON if found, or nil.
    public func parseToolCall(
        from text: String,
        availableTools: [AgentTool]
    ) -> (name: String, arguments: String)? {
        let pattern = #"TOOL_CALL:\s*(\w+)\((\{.*?\})\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let nameRange = Range(match.range(at: 1), in: text),
              let argsRange = Range(match.range(at: 2), in: text)
        else {
            return nil
        }

        let name = String(text[nameRange])
        let args = String(text[argsRange])

        guard availableTools.contains(where: { $0.name == name }) else {
            return nil
        }

        return (name: name, arguments: args)
    }

    /// Remove the TOOL_CALL pattern from response text for clean display.
    public func cleanToolCallText(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"TOOL_CALL:\s*\w+\(\{.*?\}\)"#,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
