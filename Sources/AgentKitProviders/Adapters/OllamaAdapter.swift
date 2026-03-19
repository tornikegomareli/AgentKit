import Foundation
import AgentKitCore
import os.log

/// LLM adapter for locally running Ollama models.
///
/// Uses raw URLSession against Ollama's `/api/chat` endpoint.
/// No third-party SDK dependency. Supports streaming and tool calling
/// for models that have function calling capability (llama3.1+, mistral, etc.).
public final class OllamaAdapter: LLMAdapter, @unchecked Sendable {
    private let baseURL: URL
    private let model: String
    private let logger = Logger(subsystem: "com.agentkit.providers", category: "OllamaAdapter")

    /// Initialize an Ollama adapter.
    ///
    /// - Parameters:
    ///   - model: The Ollama model name (e.g. "llama3.1", "mistral").
    ///   - host: The Ollama server host. Defaults to localhost:11434.
    public init(
        model: String,
        host: String = "http://localhost:11434"
    ) {
        self.model = model
        self.baseURL = URL(string: host)!  // swiftlint:disable:this force_unwrapping
    }

    public func respond(
        messages: [AgentMessage],
        tools: [AgentTool],
        context: AgentContext
    ) async throws -> AsyncThrowingStream<AgentLoopEvent, Error> {
        let body = buildRequestBody(messages: messages, tools: tools, context: context)

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            throw AgentError.unknown(NSError(
                domain: "OllamaAdapter",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"]
            ))
        }

        let url = baseURL.appendingPathComponent("/api/chat")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await URLSession.shared.bytes(for: request)
        } catch {
            throw AgentError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AgentError.providerUnavailable("Ollama returned non-200 status")
        }

        return AsyncThrowingStream { continuation in
            Task {
                var accumulatedText = ""

                do {
                    for try await line in bytes.lines {
                        guard let data = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        else { continue }

                        // Check for tool calls
                        if let message = json["message"] as? [String: Any],
                           let toolCalls = message["tool_calls"] as? [[String: Any]] {
                            for tc in toolCalls {
                                if let function = tc["function"] as? [String: Any],
                                   let name = function["name"] as? String {
                                    continuation.yield(.toolCallStarted(name: name))
                                    let args: String
                                    if let arguments = function["arguments"] as? [String: Any],
                                       let argsData = try? JSONSerialization.data(withJSONObject: arguments) {
                                        args = String(data: argsData, encoding: .utf8) ?? "{}"
                                    } else {
                                        args = "{}"
                                    }
                                    continuation.yield(.toolCallCompleted(name: name, result: args))
                                }
                            }
                        }

                        // Check for text content
                        if let message = json["message"] as? [String: Any],
                           let content = message["content"] as? String,
                           !content.isEmpty {
                            accumulatedText += content
                            continuation.yield(.token(content))
                        }

                        // Check if done
                        if let done = json["done"] as? Bool, done {
                            if !accumulatedText.isEmpty {
                                continuation.yield(.responseComplete(accumulatedText))
                            }
                            continuation.finish()
                            return
                        }
                    }

                    // Stream ended
                    if !accumulatedText.isEmpty {
                        continuation.yield(.responseComplete(accumulatedText))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: AgentError.unknown(error))
                }
            }
        }
    }

    // MARK: - Private

    private func buildRequestBody(
        messages: [AgentMessage],
        tools: [AgentTool],
        context: AgentContext
    ) -> [String: Any] {
        var ollamaMessages: [[String: Any]] = []

        // System message with context
        var systemParts: [String] = []
        if let systemPrompt = context.systemPrompt {
            systemParts.append(systemPrompt)
        } else {
            systemParts.append("You are a helpful assistant.")
        }
        if let screen = context.currentScreen {
            systemParts.append("The user is on the '\(screen)' screen.")
        }
        if !context.customState.isEmpty {
            systemParts.append("App state: \(context.customState.description)")
        }
        ollamaMessages.append([
            "role": "system",
            "content": systemParts.joined(separator: " ")
        ])

        for message in messages {
            switch message {
            case .user(let text):
                ollamaMessages.append(["role": "user", "content": text])
            case .assistant(let text):
                ollamaMessages.append(["role": "assistant", "content": text])
            case .toolCall(let name, let params):
                ollamaMessages.append([
                    "role": "assistant",
                    "content": "",
                    "tool_calls": [[
                        "function": [
                            "name": name,
                            "arguments": params.storage
                        ] as [String: Any]
                    ]]
                ])
            case .toolResult(_, let result):
                ollamaMessages.append([
                    "role": "tool",
                    "content": result
                ])
            }
        }

        var body: [String: Any] = [
            "model": model,
            "messages": ollamaMessages,
            "stream": true
        ]

        // Add tools if model supports them
        if !tools.isEmpty {
            body["tools"] = tools.map { tool in
                [
                    "type": "function",
                    "function": [
                        "name": tool.name,
                        "description": tool.description,
                        "parameters": buildToolParameters(tool.parameters)
                    ] as [String: Any]
                ] as [String: Any]
            }
        }

        return body
    }

    private func buildToolParameters(_ params: [ToolParameter]) -> [String: Any] {
        guard !params.isEmpty else {
            return ["type": "object", "properties": [:] as [String: Any]]
        }

        var properties: [String: Any] = [:]
        var required: [String] = []

        for param in params {
            properties[param.name] = [
                "type": param.typeName,
                "description": param.description
            ] as [String: Any]
            if param.isRequired {
                required.append(param.name)
            }
        }

        var result: [String: Any] = [
            "type": "object",
            "properties": properties
        ]
        if !required.isEmpty {
            result["required"] = required
        }
        return result
    }
}
