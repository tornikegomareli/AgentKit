import Foundation
import AgentKitCore
import SwiftAnthropic

/// Translates AgentKit tool definitions to Anthropic's tool schema format.
enum AnthropicSchema {

    /// Convert an ``AgentTool`` to SwiftAnthropic's `MessageParameter.Tool`.
    static func tool(from agentTool: AgentTool) -> MessageParameter.Tool {
        let properties = agentTool.parameters.reduce(
            into: [String: JSONSchema.Property]()
        ) { result, param in
            result[param.name] = JSONSchema.Property(
                type: jsonType(for: param),
                description: param.description
            )
        }

        let required = agentTool.parameters
            .filter(\.isRequired)
            .map(\.name)

        let schema = JSONSchema(
            type: .object,
            properties: properties.isEmpty ? nil : properties,
            required: required.isEmpty ? nil : required
        )

        return .function(
            name: agentTool.name,
            description: agentTool.description,
            inputSchema: schema
        )
    }

    /// Convert an array of ``AgentTool`` to Anthropic tools.
    static func tools(from agentTools: [AgentTool]) -> [MessageParameter.Tool]? {
        guard !agentTools.isEmpty else { return nil }
        return agentTools.map { tool(from: $0) }
    }

    /// Convert ``AgentMessage`` array to Anthropic's message format.
    static func messages(
        from agentMessages: [AgentMessage]
    ) -> [MessageParameter.Message] {
        var result: [MessageParameter.Message] = []

        for message in agentMessages {
            switch message {
            case .user(let text):
                result.append(.init(role: .user, content: .text(text)))

            case .assistant(let text):
                result.append(.init(role: .assistant, content: .text(text)))

            case .toolCall(let name, let params):
                // Represent the assistant's tool use as a content block
                let input = dynamicContent(from: params)
                let toolUseId = "tool_\(name)_\(UUID().uuidString.prefix(8))"
                result.append(.init(
                    role: .assistant,
                    content: .list([
                        .toolUse(toolUseId, name, input)
                    ])
                ))

            case .toolResult(let name, let resultText):
                // Find the matching tool use ID from the previous assistant message
                let toolUseId = findToolUseId(for: name, in: result)
                result.append(.init(
                    role: .user,
                    content: .list([
                        .toolResult(toolUseId, resultText)
                    ])
                ))
            }
        }

        return result
    }

    /// Convert ``SendableDictionary`` to Anthropic's `DynamicContent` format.
    static func dynamicContent(
        from dict: SendableDictionary
    ) -> [String: MessageResponse.Content.DynamicContent] {
        var result: [String: MessageResponse.Content.DynamicContent] = [:]
        for key in dict.keys {
            guard let value = dict[key] else { continue }
            result[key] = toDynamic(value)
        }
        return result
    }

    /// Convert Anthropic's `DynamicContent` input to ``SendableDictionary``.
    static func sendableDictionary(
        from input: [String: MessageResponse.Content.DynamicContent]
    ) -> SendableDictionary {
        var result: [String: Any] = [:]
        for (key, value) in input {
            result[key] = fromDynamic(value)
        }
        return SendableDictionary(result)
    }

    // MARK: - Private Helpers

    private static func jsonType(for param: ToolParameter) -> JSONSchema.JSONType {
        switch param {
        case .string: return .string
        case .int: return .integer
        case .bool: return .boolean
        case .object: return .object
        case .array: return .array
        case .number: return .number
        }
    }

    private static func toDynamic(_ value: Any) -> MessageResponse.Content.DynamicContent {
        switch value {
        case let s as String:
            return .string(s)
        case let i as Int:
            return .integer(i)
        case let d as Double:
            return .double(d)
        case let b as Bool:
            return .bool(b)
        default:
            return .string(String(describing: value))
        }
    }

    private static func fromDynamic(
        _ value: MessageResponse.Content.DynamicContent
    ) -> Any {
        switch value {
        case .string(let s): return s
        case .integer(let i): return i
        case .double(let d): return d
        case .bool(let b): return b
        case .null: return NSNull()
        case .array(let arr): return arr.map { fromDynamic($0) }
        case .dictionary(let dict):
            var result: [String: Any] = [:]
            for (k, v) in dict { result[k] = fromDynamic(v) }
            return result
        }
    }

    private static func findToolUseId(
        for toolName: String,
        in messages: [MessageParameter.Message]
    ) -> String {
        // Walk backwards to find the matching assistant tool_use block
        for message in messages.reversed() {
            // We encode tool use IDs with the pattern "tool_{name}_{uuid}"
            // so we can match by prefix
            if case .list(let contents) = message.content {
                for content in contents {
                    if case .toolUse(let id, let name, _) = content, name == toolName {
                        return id
                    }
                }
            }
        }
        return "tool_\(toolName)_unknown"
    }
}
