import Foundation
import os.log

/// A conversation session with the agent.
///
/// `AgentSession` is the primary interface for sending messages and receiving
/// events. It maintains conversation history and exposes an event stream
/// that any UI — custom or ``AgentKitChat`` — can consume.
///
/// Uses the Observation framework (`@Observable`) on iOS 17+ for automatic
/// SwiftUI integration. On iOS 16, use the ``events`` async stream directly.
///
/// ## Headless Usage
/// ```swift
/// let session = agent.startSession()
/// session.send("Book a table for 2 tomorrow")
///
/// for await event in session.events {
///     switch event {
///     case .token(let t):              appendToChat(t)
///     case .toolCallStarted(let name): showLoader(name)
///     case .toolCallCompleted:         hideLoader()
///     case .responseComplete:          finalize()
///     case .error(let e):              showError(e)
///     }
/// }
/// ```
@available(iOS 17.0, macOS 14.0, *)
@Observable
public final class AgentSession: @unchecked Sendable {
    // MARK: - Observable State

    /// All messages in the conversation.
    public private(set) var messages: [AgentMessage] = []

    /// Whether the agent is currently processing a request.
    public private(set) var isProcessing: Bool = false

    /// The most recent error, if any.
    public private(set) var lastError: AgentError?

    // MARK: - Private

    private let loopRunner: AgentLoopRunner
    private let logger = Logger(subsystem: "com.agentkit", category: "AgentSession")
    private var currentTask: Task<Void, Never>?

    /// Async stream of events from the current agent turn.
    /// Consumers iterate this to drive UI updates.
    private var eventContinuation: AsyncStream<AgentLoopEvent>.Continuation?

    /// The async stream of events for the current or most recent turn.
    public private(set) var events: AsyncStream<AgentLoopEvent>

    public init(loopRunner: AgentLoopRunner) {
        self.loopRunner = loopRunner
        var continuation: AsyncStream<AgentLoopEvent>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation
    }

    // MARK: - Public API

    /// Send a user message and begin the agent's response.
    ///
    /// This starts a new turn of the agent loop. Events are emitted
    /// to the ``events`` stream and the ``messages`` array is updated
    /// as the conversation progresses.
    ///
    /// If a previous turn is still running, it is cancelled first.
    public func send(_ text: String) {
        // Cancel any in-flight request
        currentTask?.cancel()

        // Reset event stream
        eventContinuation?.finish()
        var continuation: AsyncStream<AgentLoopEvent>.Continuation!
        events = AsyncStream { continuation = $0 }
        eventContinuation = continuation

        // Add user message
        messages.append(.user(text))
        isProcessing = true
        lastError = nil

        // Start the agent loop
        currentTask = Task { [weak self] in
            guard let self else { return }

            let loopStream = await self.loopRunner.run(messages: self.messages)

            do {
                for try await event in loopStream {
                    await self.handleEvent(event)
                }
            } catch is CancellationError {
                await self.finish()
            } catch {
                let agentError: AgentError
                if let ae = error as? AgentError {
                    agentError = ae
                } else {
                    agentError = .unknown(error)
                }
                await self.handleEvent(.error(agentError))
            }

            await self.finish()
        }
    }

    /// Cancel the current agent turn.
    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isProcessing = false
    }

    /// Clear all conversation history and start fresh.
    public func reset() {
        cancel()
        messages.removeAll()
        lastError = nil
    }

    // MARK: - Private

    @MainActor
    private func handleEvent(_ event: AgentLoopEvent) {
        eventContinuation?.yield(event)

        switch event {
        case .token:
            break // UI handles token accumulation

        case .toolCallStarted(let name):
            messages.append(.toolCall(name: name, params: [:]))

        case .toolCallCompleted(let name, let result):
            // Update the last toolCall entry with the result params, then add result
            if let lastIndex = messages.lastIndex(where: {
                if case .toolCall(let n, _) = $0, n == name { return true }
                return false
            }) {
                // Replace placeholder with actual params if available
                messages[lastIndex] = .toolCall(name: name, params: [:])
            }
            messages.append(.toolResult(name: name, result: result))

        case .responseComplete(let text):
            messages.append(.assistant(text))
            isProcessing = false

        case .error(let error):
            lastError = error
            isProcessing = false
        }
    }

    @MainActor
    private func finish() {
        isProcessing = false
        eventContinuation?.finish()
    }
}

// MARK: - iOS 16 Fallback

/// A non-Observable session for iOS 16 support.
/// Uses async streams directly without @Observable.
public final class AgentSessionLegacy: @unchecked Sendable {
    public private(set) var messages: [AgentMessage] = []
    public private(set) var isProcessing: Bool = false

    private let loopRunner: AgentLoopRunner
    private var currentTask: Task<Void, Never>?
    private var eventContinuation: AsyncStream<AgentLoopEvent>.Continuation?
    public private(set) var events: AsyncStream<AgentLoopEvent>

    public init(loopRunner: AgentLoopRunner) {
        self.loopRunner = loopRunner
        var continuation: AsyncStream<AgentLoopEvent>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation
    }

    public func send(_ text: String) {
        currentTask?.cancel()

        eventContinuation?.finish()
        var continuation: AsyncStream<AgentLoopEvent>.Continuation!
        events = AsyncStream { continuation = $0 }
        eventContinuation = continuation

        messages.append(.user(text))
        isProcessing = true

        currentTask = Task { [weak self] in
            guard let self else { return }

            let loopStream = await self.loopRunner.run(messages: self.messages)

            do {
                for try await event in loopStream {
                    self.handleEvent(event)
                    self.eventContinuation?.yield(event)
                }
            } catch {
                // Stream ended
            }

            self.isProcessing = false
            self.eventContinuation?.finish()
        }
    }

    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isProcessing = false
    }

    public func reset() {
        cancel()
        messages.removeAll()
    }

    private func handleEvent(_ event: AgentLoopEvent) {
        switch event {
        case .toolCallStarted(let name):
            messages.append(.toolCall(name: name, params: [:]))
        case .responseComplete(let text):
            messages.append(.assistant(text))
        case .toolCallCompleted(let name, let result):
            messages.append(.toolResult(name: name, result: result))
        default:
            break
        }
    }
}
