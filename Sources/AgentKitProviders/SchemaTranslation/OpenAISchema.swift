import Foundation
import AgentKitCore
import OpenAI

/// Translates AgentKit tool definitions to OpenAI's chat completion format.
enum OpenAISchema {

    /// Convert an ``AgentTool`` to OpenAI's `ChatCompletionToolParam`.
    static func tool(from agentTool: AgentTool) -> ChatQuery.ChatCompletionToolParam {
        let functionDef = ChatQuery.ChatCompletionToolParam.FunctionDefinition(
            name: agentTool.name,
            description: agentTool.description,
            parameters: jsonSchema(from: agentTool.parameters)
        )
        return .init(function: functionDef)
    }

    /// Convert an array of ``AgentTool`` to OpenAI tools.
    static func tools(from agentTools: [AgentTool]) -> [ChatQuery.ChatCompletionToolParam]? {
        guard !agentTools.isEmpty else { return nil }
        return agentTools.map { tool(from: $0) }
    }

    /// Convert ``AgentMessage`` array to OpenAI's message format.
    static func messages(
        from agentMessages: [AgentMessage],
        systemPrompt: String?
    ) -> [ChatQuery.ChatCompletionMessageParam] {
        var result: [ChatQuery.ChatCompletionMessageParam] = []

        if let systemPrompt {
            result.append(.system(
                .init(content: .textContent(systemPrompt))
            ))
        }

        for message in agentMessages {
            switch message {
            case .user(let text):
                result.append(.user(
                    .init(content: .string(text))
                ))

            case .assistant(let text):
                result.append(.assistant(
                    .init(content: .textContent(text))
                ))

            case .toolCall(let name, let params):
                let argsJSON = jsonString(from: params)
                let callId = "call_\(name)_\(UUID().uuidString.prefix(8))"
                let toolCallParam = ChatQuery.ChatCompletionMessageParam
                    .AssistantMessageParam.ToolCallParam(
                        id: callId,
                        function: .init(arguments: argsJSON, name: name)
                    )
                result.append(.assistant(
                    .init(toolCalls: [toolCallParam])
                ))

            case .toolResult(let name, let resultText):
                let callId = findCallId(for: name, in: result)
                result.append(.tool(
                    .init(
                        content: .textContent(resultText),
                        toolCallId: callId
                    )
                ))
            }
        }

        return result
    }

    /// Parse a JSON arguments string into a ``SendableDictionary``.
    static func parseArguments(_ arguments: String) -> SendableDictionary {
        guard let data = arguments.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return SendableDictionary(["_raw": arguments])
        }
        return SendableDictionary(json)
    }

    // MARK: - Private Helpers

    private static func jsonSchema(
        from parameters: [ToolParameter]
    ) -> JSONSchema? {
        guard !parameters.isEmpty else { return nil }

        // Build each property as a JSONSchema
        var properties: [String: JSONSchema] = [:]
        var requiredNames: [String] = []

        for param in parameters {
            properties[param.name] = JSONSchema(
                .type(schemaType(for: param)),
                .description(param.description)
            )
            if param.isRequired {
                requiredNames.append(param.name)
            }
        }

        // Build the root object schema using the SDK's field helpers
        var fields: [JSONSchemaField] = [
            .type(.object),
            .properties(properties),
        ]
        if !requiredNames.isEmpty {
            fields.append(.required(requiredNames))
        }

        return JSONSchema(fields: fields)
    }

    private static func schemaType(for param: ToolParameter) -> JSONSchemaInstanceType {
        switch param {
        case .string: return .string
        case .int: return .integer
        case .bool: return .boolean
        case .object: return .object
        case .array: return .array
        case .number: return .number
        }
    }

    private static func jsonString(from dict: SendableDictionary) -> String {
        guard let data = try? JSONSerialization.data(
            withJSONObject: dict.storage,
            options: [.sortedKeys]
        ) else {
            return "{}"
        }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private static func findCallId(
        for toolName: String,
        in messages: [ChatQuery.ChatCompletionMessageParam]
    ) -> String {
        for message in messages.reversed() {
            if case .assistant(let assistantParam) = message,
               let toolCalls = assistantParam.toolCalls {
                for tc in toolCalls {
                    if tc.function.name == toolName {
                        return tc.id
                    }
                }
            }
        }
        return "call_\(toolName)_unknown"
    }
}
