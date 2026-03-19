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

        var properties: [String: AnyJSONDocument] = [:]
        var required: [AnyJSONDocument] = []

        for param in parameters {
            let propDict: [String: AnyJSONDocument] = [
                "type": AnyJSONDocument(param.typeName as any JSONDocument),
                "description": AnyJSONDocument(param.description as any JSONDocument)
            ]
            properties[param.name] = AnyJSONDocument(propDict as any JSONDocument)
            if param.isRequired {
                required.append(AnyJSONDocument(param.name as any JSONDocument))
            }
        }

        var schema: [String: AnyJSONDocument] = [
            "type": AnyJSONDocument("object" as any JSONDocument),
            "properties": AnyJSONDocument(properties as any JSONDocument)
        ]
        if !required.isEmpty {
            schema["required"] = AnyJSONDocument(required as any JSONDocument)
        }

        return .object(schema)
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
