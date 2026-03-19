import Testing
import Foundation
@testable import AgentKitCore
import AgentKitTestSupport

@Suite("ToolRegistry Tests")
struct ToolRegistryTests {

    @Test("Register and execute a tool")
    func testToolRegistrationAndExecution() async throws {
        let registry = ToolRegistry()

        await registry.register(
            name: "getOrderStatus",
            description: "Get the status of an order by ID",
            parameters: [
                .string("orderId", description: "The order identifier", required: true)
            ]
        ) { params in
            let orderId = params["orderId"] as? String ?? "unknown"
            return "Order \(orderId) is shipped"
        }

        let count = await registry.count
        #expect(count == 1)

        let result = try await registry.execute(
            name: "getOrderStatus",
            params: SendableDictionary(["orderId": "ABC123"])
        )
        #expect(result == "Order ABC123 is shipped")
    }

    @Test("Execute unregistered tool throws toolNotFound")
    func testToolNotFound() async {
        let registry = ToolRegistry()

        do {
            _ = try await registry.execute(name: "nonExistent", params: [:])
            Issue.record("Expected toolNotFound error")
        } catch let error as AgentError {
            if case .toolNotFound(let name) = error {
                #expect(name == "nonExistent")
            } else {
                Issue.record("Expected toolNotFound, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Tool execution failure is wrapped in toolExecutionFailed")
    func testToolExecutionFailed() async {
        let registry = ToolRegistry()

        struct TestError: Error {}

        await registry.register(
            name: "failingTool",
            description: "A tool that always fails"
        ) { _ in
            throw TestError()
        }

        do {
            _ = try await registry.execute(name: "failingTool", params: [:])
            Issue.record("Expected toolExecutionFailed error")
        } catch let error as AgentError {
            if case .toolExecutionFailed(let name, _) = error {
                #expect(name == "failingTool")
            } else {
                Issue.record("Expected toolExecutionFailed, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Shorthand registration works")
    func testShorthandRegistration() async throws {
        let registry = ToolRegistry()

        await registry.register("ping") { _ in "pong" }

        let result = try await registry.execute(name: "ping", params: [:])
        #expect(result == "pong")
    }

    @Test("Unregister removes a tool")
    func testUnregister() async {
        let registry = ToolRegistry()

        await registry.register("temp") { _ in "value" }
        let countBefore = await registry.count
        #expect(countBefore == 1)

        let removed = await registry.unregister("temp")
        #expect(removed == true)

        let countAfter = await registry.count
        #expect(countAfter == 0)
    }

    @Test("allTools returns all registered tools")
    func testAllTools() async {
        let registry = ToolRegistry()

        await registry.register("a") { _ in "a" }
        await registry.register("b") { _ in "b" }
        await registry.register("c") { _ in "c" }

        let tools = await registry.allTools()
        #expect(tools.count == 3)

        let names = Set(tools.map(\.name))
        #expect(names == Set(["a", "b", "c"]))
    }
}
