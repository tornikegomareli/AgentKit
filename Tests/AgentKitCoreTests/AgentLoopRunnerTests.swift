import Testing
import Foundation
@testable import AgentKitCore
import AgentKitTestSupport

@Suite("AgentLoopRunner Tests")
struct AgentLoopRunnerTests {

    @Test("Loop terminates when LLM returns a text response with no tool calls")
    func testLoopTermination() async throws {
        let mock = MockLLMAdapter()
        mock.responses = [.text("Hello, I'm your assistant.")]

        let runner = AgentLoopRunner(
            adapter: mock,
            toolRegistry: ToolRegistry(),
            stateManager: StateManager()
        )

        let messages: [AgentMessage] = [.user("Hi")]
        let stream = await runner.run(messages: messages)

        var events: [AgentLoopEvent] = []
        for try await event in stream {
            events.append(event)
        }

        // Should have tokens + responseComplete
        let completeEvents = events.filter {
            if case .responseComplete = $0 { return true }
            return false
        }
        #expect(completeEvents.count == 1)

        if case .responseComplete(let text) = completeEvents.first {
            #expect(text == "Hello, I'm your assistant.")
        }
    }

    @Test("Loop executes tool call and feeds result back")
    func testToolRegistrationAndExecution() async throws {
        let mock = MockLLMAdapter()
        // First response: tool call. Second response: text using tool result.
        mock.responses = [
            .toolCall(name: "getWeather", params: "{\"city\": \"SF\"}"),
            .text("The weather in SF is sunny.")
        ]

        let registry = ToolRegistry()
        await registry.register(
            name: "getWeather",
            description: "Get weather for a city",
            parameters: [.string("city", description: "City name", required: true)]
        ) { params in
            let city = params["city"] as? String ?? "unknown"
            return "Sunny in \(city)"
        }

        let runner = AgentLoopRunner(
            adapter: mock,
            toolRegistry: registry,
            stateManager: StateManager()
        )

        let messages: [AgentMessage] = [.user("What's the weather in SF?")]
        let stream = await runner.run(messages: messages)

        var events: [AgentLoopEvent] = []
        for try await event in stream {
            events.append(event)
        }

        // Should have tool start, tool complete, then text response
        let toolStarts = events.filter {
            if case .toolCallStarted = $0 { return true }
            return false
        }
        let toolCompletes = events.filter {
            if case .toolCallCompleted = $0 { return true }
            return false
        }
        let completes = events.filter {
            if case .responseComplete = $0 { return true }
            return false
        }

        #expect(toolStarts.count == 1)
        #expect(toolCompletes.count == 1)
        #expect(completes.count == 1)

        // Verify the mock was called twice (once for tool call, once for final response)
        #expect(mock.calls.count == 2)
    }

    @Test("Loop stops at max iterations and throws maxIterationsExceeded")
    func testMaxIterationGuard() async throws {
        let mock = MockLLMAdapter()
        // Always request a tool call — should hit max iterations
        mock.responses = Array(repeating: MockResponse.toolCall(name: "loop", params: "{}"), count: 15)

        let registry = ToolRegistry()
        await registry.register("loop") { _ in "looping" }

        let config = Configuration(maxIterations: 3)
        let runner = AgentLoopRunner(
            adapter: mock,
            toolRegistry: registry,
            stateManager: StateManager(),
            configuration: config
        )

        let messages: [AgentMessage] = [.user("Loop forever")]
        let stream = await runner.run(messages: messages)

        var hitMaxIterations = false
        do {
            for try await event in stream {
                if case .error(let error) = event {
                    if case .maxIterationsExceeded = error {
                        hitMaxIterations = true
                    }
                }
            }
        } catch let error as AgentError {
            if case .maxIterationsExceeded = error {
                hitMaxIterations = true
            }
        } catch {
            // Other errors are acceptable here
        }

        #expect(hitMaxIterations == true)
        // Should have been called exactly maxIterations times
        #expect(mock.calls.count == 3)
    }

    @Test("Offline fallback is used when primary adapter throws network error")
    func testOfflineFallback() async throws {
        let primary = MockLLMAdapter()
        primary.errorToThrow = AgentError.networkUnavailable

        let fallback = MockLLMAdapter()
        fallback.responses = [.text("Fallback response")]

        let runner = AgentLoopRunner(
            adapter: primary,
            fallbackAdapter: fallback,
            toolRegistry: ToolRegistry(),
            stateManager: StateManager()
        )

        let messages: [AgentMessage] = [.user("Hello")]
        let stream = await runner.run(messages: messages)

        var events: [AgentLoopEvent] = []
        for try await event in stream {
            events.append(event)
        }

        // Should have gotten response from fallback
        let completeEvents = events.filter {
            if case .responseComplete = $0 { return true }
            return false
        }
        #expect(completeEvents.count == 1)
        #expect(fallback.calls.count == 1)
    }

    @Test("State manager is called before each LLM call")
    func testContextPull() async throws {
        let mock = MockLLMAdapter()
        mock.responses = [.text("Got your context")]

        let stateProvider = MockAgentStateProvider(
            context: AgentContext(currentScreen: "home")
        )
        let stateManager = StateManager()
        await stateManager.setProvider(stateProvider)

        let runner = AgentLoopRunner(
            adapter: mock,
            toolRegistry: ToolRegistry(),
            stateManager: stateManager
        )

        let stream = await runner.run(messages: [.user("Hi")])
        for try await _ in stream {}

        // State provider should have been called
        #expect(stateProvider.snapshotCallCount >= 1)

        // The mock should have received the context
        #expect(mock.calls.first?.context.currentScreen == "home")
    }
}
