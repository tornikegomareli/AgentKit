import Foundation
import os.log

/// The core reasoning loop that drives agent behavior.
///
/// On each user message, the loop:
/// 1. Pulls current app state via ``StateManager``
/// 2. Sends the conversation + tools to the LLM
/// 3. Streams events (tokens, tool calls) back to the caller
/// 4. If the LLM requests a tool call, executes it and loops back to step 1
/// 5. Terminates when the LLM returns a final response with no tool calls
///
/// The loop is bounded by ``Configuration/maxIterations`` to prevent
/// infinite tool-call chains. Supports Swift structured concurrency
/// cancellation at every iteration boundary.
public actor AgentLoopRunner {
    private let adapter: any LLMAdapter
    private let fallbackAdapter: (any LLMAdapter)?
    private let toolRegistry: ToolRegistry
    private let stateManager: StateManager
    private let configuration: Configuration
    private let logger = Logger(subsystem: "com.agentkit", category: "AgentLoop")

    public init(
        adapter: any LLMAdapter,
        fallbackAdapter: (any LLMAdapter)? = nil,
        toolRegistry: ToolRegistry,
        stateManager: StateManager,
        configuration: Configuration = .default
    ) {
        self.adapter = adapter
        self.fallbackAdapter = fallbackAdapter
        self.toolRegistry = toolRegistry
        self.stateManager = stateManager
        self.configuration = configuration
    }

    /// Run the agent loop for a user message.
    ///
    /// Returns an `AsyncThrowingStream` of ``AgentLoopEvent`` that the caller
    /// can iterate over to drive a UI or headless session.
    ///
    /// - Parameter messages: The full conversation history including the new user message.
    /// - Returns: A stream of events representing the agent's response.
    public func run(messages: [AgentMessage]) -> AsyncThrowingStream<AgentLoopEvent, Error> {
        let adapter = self.adapter
        let fallbackAdapter = self.fallbackAdapter
        let toolRegistry = self.toolRegistry
        let stateManager = self.stateManager
        let configuration = self.configuration
        let logger = self.logger

        return AsyncThrowingStream { continuation in
            let task = Task {
                var currentMessages = messages
                var iterations = 0

                while iterations < configuration.maxIterations {
                    // Check for cancellation at each iteration boundary
                    try Task.checkCancellation()

                    iterations += 1
                    if configuration.loggingEnabled {
                        logger.debug("Loop iteration \(iterations)/\(configuration.maxIterations)")
                    }

                    // Pull current state
                    let context = await stateManager.currentContext()
                    let tools = await toolRegistry.allTools()

                    // Call LLM (with fallback on network failure)
                    let stream: AsyncThrowingStream<AgentLoopEvent, Error>
                    do {
                        stream = try await adapter.respond(
                            messages: currentMessages,
                            tools: tools,
                            context: context
                        )
                    } catch {
                        // Attempt fallback if primary fails with network error
                        if let fallback = fallbackAdapter, isNetworkError(error) {
                            if configuration.loggingEnabled {
                                logger.debug("Primary adapter failed, using fallback")
                            }
                            do {
                                stream = try await fallback.respond(
                                    messages: currentMessages,
                                    tools: tools,
                                    context: context
                                )
                            } catch {
                                continuation.finish(throwing: error)
                                return
                            }
                        } else {
                            continuation.finish(throwing: error)
                            return
                        }
                    }

                    // Process the event stream
                    var shouldContinue = false
                    var accumulatedResponse = ""

                    do {
                        for try await event in stream {
                            try Task.checkCancellation()

                            switch event {
                            case .token(let token):
                                accumulatedResponse += token
                                continuation.yield(.token(token))

                            case .toolCallStarted(let name):
                                continuation.yield(.toolCallStarted(name: name))

                            case .toolCallCompleted(let name, let params):
                                // Execute the tool
                                let paramsDict = parseToolParams(params)
                                do {
                                    let result = try await toolRegistry.execute(
                                        name: name,
                                        params: paramsDict
                                    )
                                    continuation.yield(.toolCallCompleted(name: name, result: result))

                                    // Append tool call and result to messages for next iteration
                                    currentMessages.append(.toolCall(name: name, params: paramsDict))
                                    currentMessages.append(.toolResult(name: name, result: result))
                                    shouldContinue = true
                                } catch {
                                    let errorResult = "Error: \(error)"
                                    continuation.yield(.toolCallCompleted(name: name, result: errorResult))
                                    currentMessages.append(.toolCall(name: name, params: paramsDict))
                                    currentMessages.append(.toolResult(name: name, result: errorResult))
                                    shouldContinue = true
                                }

                            case .responseComplete(let text):
                                continuation.yield(.responseComplete(text))
                                continuation.finish()
                                return

                            case .error(let agentError):
                                continuation.yield(.error(agentError))
                                continuation.finish(throwing: agentError)
                                return
                            }
                        }
                    } catch is CancellationError {
                        continuation.finish(throwing: AgentError.cancelled)
                        return
                    } catch {
                        continuation.finish(throwing: error)
                        return
                    }

                    // If no tool call was made and we got tokens but no responseComplete,
                    // treat the accumulated response as complete
                    if !shouldContinue {
                        if !accumulatedResponse.isEmpty {
                            continuation.yield(.responseComplete(accumulatedResponse))
                        }
                        continuation.finish()
                        return
                    }
                }

                // Exceeded max iterations
                let error = AgentError.maxIterationsExceeded
                continuation.yield(.error(error))
                continuation.finish(throwing: error)
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Private Helpers

    private nonisolated func isNetworkError(_ error: Error) -> Bool {
        if let agentError = error as? AgentError {
            if case .networkUnavailable = agentError {
                return true
            }
        }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain
    }

    private nonisolated func parseToolParams(_ jsonString: String) -> SendableDictionary {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return SendableDictionary(["_raw": jsonString])
        }
        return SendableDictionary(json)
    }
}
