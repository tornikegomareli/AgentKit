import Foundation
import AgentKitCore
import OpenAI
import os.log

/// LLM adapter for OpenAI models (and OpenAI-compatible APIs like Groq)
/// via the MacPaw/OpenAI SDK.
///
/// Handles streaming responses, tool call accumulation across chunks,
/// and parallel tool calls.
public final class OpenAIAdapter: LLMAdapter, @unchecked Sendable {
    private let client: OpenAI
    private let model: String
    private let systemPrompt: String?
    private let logger = Logger(subsystem: "com.agentkit.providers", category: "OpenAIAdapter")

    /// Initialize an OpenAI adapter.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key (or Groq key for compatible endpoints).
    ///   - model: The model identifier. Defaults to GPT-4o.
    ///   - host: API host. Override for Groq or other compatible endpoints.
    ///   - systemPrompt: Optional system prompt prepended to every conversation.
    public init(
        apiKey: String,
        model: String = "gpt-4o",
        host: String = "api.openai.com",
        systemPrompt: String? = nil
    ) {
        let config = OpenAI.Configuration(
            token: apiKey,
            host: host,
            timeoutInterval: 120.0
        )
        self.client = OpenAI(configuration: config)
        self.model = model
        self.systemPrompt = systemPrompt
    }

    public func respond(
        messages: [AgentMessage],
        tools: [AgentTool],
        context: AgentContext
    ) async throws -> AsyncThrowingStream<AgentLoopEvent, Error> {
        let effectiveSystemPrompt = buildSystemPrompt(
            basePrompt: systemPrompt,
            context: context
        )
        let openAIMessages = OpenAISchema.messages(
            from: messages,
            systemPrompt: effectiveSystemPrompt
        )
        let openAITools = OpenAISchema.tools(from: tools)

        let query = ChatQuery(
            messages: openAIMessages,
            model: model,
            toolChoice: openAITools != nil ? .auto : nil,
            tools: openAITools
        )

        return AsyncThrowingStream { continuation in
            Task {
                var accumulatedText = ""
                // Track tool calls: index -> (id, name, accumulatedArgs)
                var toolCallAccumulators: [Int: ToolCallAccumulator] = [:]

                do {
                    let stream: AsyncThrowingStream<ChatStreamResult, Error> = client.chatsStream(query: query)

                    for try await chunk in stream {
                        for choice in chunk.choices {
                            // Text delta
                            if let text = choice.delta.content {
                                accumulatedText += text
                                continuation.yield(.token(text))
                            }

                            // Tool call deltas
                            if let toolCalls = choice.delta.toolCalls {
                                for tc in toolCalls {
                                    let index = tc.index ?? 0

                                    if toolCallAccumulators[index] == nil {
                                        toolCallAccumulators[index] = ToolCallAccumulator()
                                    }

                                    // First chunk for this tool call has id and name
                                    if let id = tc.id {
                                        toolCallAccumulators[index]?.id = id
                                    }
                                    if let name = tc.function?.name {
                                        toolCallAccumulators[index]?.name = name
                                        continuation.yield(.toolCallStarted(name: name))
                                    }
                                    // Accumulate argument fragments
                                    if let args = tc.function?.arguments {
                                        toolCallAccumulators[index]?.arguments += args
                                    }
                                }
                            }

                            // Finish reason
                            if let reason = choice.finishReason {
                                switch reason {
                                case .stop:
                                    continuation.yield(.responseComplete(accumulatedText))
                                    continuation.finish()
                                    return

                                case .toolCalls:
                                    // Emit all accumulated tool calls
                                    for index in toolCallAccumulators.keys.sorted() {
                                        if let acc = toolCallAccumulators[index],
                                           let name = acc.name {
                                            continuation.yield(.toolCallCompleted(
                                                name: name,
                                                result: acc.arguments
                                            ))
                                        }
                                    }
                                    continuation.finish()
                                    return

                                case .length:
                                    if !accumulatedText.isEmpty {
                                        continuation.yield(.responseComplete(accumulatedText))
                                    }
                                    continuation.finish()
                                    return

                                default:
                                    break
                                }
                            }
                        }
                    }

                    // Stream ended without explicit finish reason
                    if !accumulatedText.isEmpty {
                        continuation.yield(.responseComplete(accumulatedText))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: mapError(error))
                }
            }
        }
    }

    // MARK: - Private

    private struct ToolCallAccumulator {
        var id: String?
        var name: String?
        var arguments: String = ""
    }

    private func buildSystemPrompt(
        basePrompt: String?,
        context: AgentContext
    ) -> String? {
        var parts: [String] = []

        // Developer's system prompt from Configuration (via context)
        if let contextPrompt = context.systemPrompt {
            parts.append(contextPrompt)
        }

        // Adapter-level base prompt (legacy, for direct adapter construction)
        if let base = basePrompt {
            parts.append(base)
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

        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }

    private func mapError(_ error: Error) -> AgentError {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkUnavailable
        }
        return .unknown(error)
    }
}
