import Foundation
import AgentKitCore
import SwiftAnthropic
import os.log

/// LLM adapter for Anthropic's Claude models via the SwiftAnthropic SDK.
///
/// Handles streaming responses, tool use blocks, and DynamicContent conversion.
/// Supports all Claude models including claude-3.5-sonnet, claude-3-opus, claude-3.7-sonnet.
public final class ClaudeAdapter: LLMAdapter, @unchecked Sendable {
    private let service: AnthropicService
    private let model: String
    private let maxTokens: Int
    private let logger = Logger(subsystem: "com.agentkit.providers", category: "ClaudeAdapter")

    /// Initialize a Claude adapter.
    ///
    /// - Parameters:
    ///   - apiKey: Your Anthropic API key.
    ///   - model: The model identifier. Defaults to Claude 3.7 Sonnet.
    ///   - maxTokens: Maximum tokens in the response. Defaults to 4096.
    public init(
        apiKey: String,
        model: String = "claude-3-7-sonnet-latest",
        maxTokens: Int = 4096
    ) {
        self.service = AnthropicServiceFactory.service(apiKey: apiKey, betaHeaders: nil)
        self.model = model
        self.maxTokens = maxTokens
    }

    public func respond(
        messages: [AgentMessage],
        tools: [AgentTool],
        context: AgentContext
    ) async throws -> AsyncThrowingStream<AgentLoopEvent, Error> {
        let systemPrompt = buildSystemPrompt(context: context)
        let anthropicMessages = AnthropicSchema.messages(from: messages)
        let anthropicTools = AnthropicSchema.tools(from: tools)

        let parameter = MessageParameter(
            model: .other(model),
            messages: anthropicMessages,
            maxTokens: maxTokens,
            system: systemPrompt.map { .text($0) },
            tools: anthropicTools,
            toolChoice: anthropicTools != nil ? MessageParameter.ToolChoice(type: .auto) : nil
        )

        let sdkStream: AsyncThrowingStream<MessageStreamResponse, Error>
        do {
            sdkStream = try await service.streamMessage(parameter)
        } catch {
            throw mapError(error)
        }

        return AsyncThrowingStream { continuation in
            Task {
                var currentToolName: String?
                var accumulatedToolJSON = ""
                var accumulatedText = ""

                do {
                    for try await event in sdkStream {
                        switch event.streamEvent {
                        case .messageStart:
                            break

                        case .contentBlockStart:
                            if let block = event.contentBlock {
                                if block.type == "tool_use" {
                                    currentToolName = block.name
                                    accumulatedToolJSON = ""
                                    if let name = block.name {
                                        continuation.yield(.toolCallStarted(name: name))
                                    }
                                }
                            }

                        case .contentBlockDelta:
                            if let delta = event.delta {
                                // Text token
                                if let text = delta.text {
                                    accumulatedText += text
                                    continuation.yield(.token(text))
                                }
                                // Tool input JSON fragment
                                if let json = delta.partialJson {
                                    accumulatedToolJSON += json
                                }
                            }

                        case .contentBlockStop:
                            // If we were accumulating a tool call, emit it
                            if let toolName = currentToolName {
                                continuation.yield(.toolCallCompleted(
                                    name: toolName,
                                    result: accumulatedToolJSON
                                ))
                                currentToolName = nil
                                accumulatedToolJSON = ""
                            }

                        case .messageDelta:
                            if let stopReason = event.delta?.stopReason {
                                if stopReason == "end_turn" || stopReason == "stop_sequence" {
                                    continuation.yield(.responseComplete(accumulatedText))
                                    continuation.finish()
                                    return
                                }
                                // "tool_use" stop reason — loop will continue in AgentLoopRunner
                                if stopReason == "tool_use" {
                                    continuation.finish()
                                    return
                                }
                            }

                        case .messageStop:
                            if !accumulatedText.isEmpty {
                                continuation.yield(.responseComplete(accumulatedText))
                            }
                            continuation.finish()
                            return

                        case .none:
                            break
                        }
                    }

                    // Stream ended without explicit stop
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

    private func buildSystemPrompt(context: AgentContext) -> String? {
        var parts: [String] = []

        if let systemPrompt = context.systemPrompt {
            parts.append(systemPrompt)
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
