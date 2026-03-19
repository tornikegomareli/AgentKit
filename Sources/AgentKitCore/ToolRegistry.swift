import Foundation
import os.log

/// Thread-safe registry for tools available to the agent.
///
/// The tool registry is the primary integration point between your app and AgentKit.
/// Register closures as tools; AgentKit translates them to whatever schema
/// the active LLM expects.
///
/// `ToolRegistry` is implemented as an actor to guarantee thread safety
/// when tools are registered from multiple contexts or executed concurrently.
///
/// ## Example
/// ```swift
/// // Full form with parameter schema
/// await agent.tools.register(
///     name: "searchProducts",
///     description: "Search the product catalog",
///     parameters: [
///         .string("query", description: "Search term", required: true),
///         .int("limit", description: "Max results", required: false)
///     ]
/// ) { params in
///     let query = params["query"] as? String ?? ""
///     return await catalog.search(query)
/// }
///
/// // Shorthand for zero-parameter tools
/// await agent.tools.register("ping") { _ in "pong" }
/// ```
public actor ToolRegistry {
    private var tools: [String: AgentTool] = [:]
    private let logger = Logger(subsystem: "com.agentkit", category: "ToolRegistry")

    public init() {}

    // MARK: - Registration

    /// Register a tool with full parameter schema.
    ///
    /// - Parameters:
    ///   - name: Unique tool identifier. Used as the function name in LLM tool schemas.
    ///   - description: Plain-English description of what the tool does and when to use it.
    ///     This text is passed directly to the LLM — quality matters.
    ///   - parameters: Typed parameter definitions. Omit for zero-parameter tools.
    ///   - handler: Async closure executed when the agent calls this tool.
    public func register(
        name: String,
        description: String,
        parameters: [ToolParameter] = [],
        handler: @escaping @Sendable (SendableDictionary) async throws -> Any
    ) {
        let tool = AgentTool(
            name: name,
            description: description,
            parameters: parameters,
            handler: handler
        )
        tools[name] = tool
        logger.debug("Registered tool: \(name)")
    }

    /// Convenience: register a tool with just a name and handler.
    /// Uses an empty description and no parameters.
    ///
    /// - Parameters:
    ///   - name: Unique tool identifier.
    ///   - handler: Async closure executed when the agent calls this tool.
    public func register(
        _ name: String,
        _ handler: @escaping @Sendable (SendableDictionary) async throws -> Any
    ) {
        register(name: name, description: name, handler: handler)
    }

    // MARK: - Execution

    /// Execute a registered tool by name.
    ///
    /// Called internally by the agent loop when the LLM requests a tool call.
    /// Converts the result to a `String` representation for feeding back to the LLM.
    ///
    /// - Parameters:
    ///   - name: The tool to execute.
    ///   - params: Arguments from the LLM.
    /// - Returns: String representation of the tool's return value.
    /// - Throws: ``AgentError/toolNotFound(_:)`` or ``AgentError/toolExecutionFailed(_:_:)``.
    public func execute(name: String, params: SendableDictionary) async throws -> String {
        guard let tool = tools[name] else {
            throw AgentError.toolNotFound(name)
        }

        do {
            let result = try await tool.handler(params)
            return String(describing: result)
        } catch {
            throw AgentError.toolExecutionFailed(name, error)
        }
    }

    // MARK: - Introspection

    /// Returns all registered tools. Used by the agent loop to pass tool
    /// definitions to the LLM adapter.
    public func allTools() -> [AgentTool] {
        Array(tools.values)
    }

    /// Returns a specific tool by name, or nil if not registered.
    public func tool(named name: String) -> AgentTool? {
        tools[name]
    }

    /// The number of currently registered tools.
    public var count: Int {
        tools.count
    }

    /// Remove a tool by name.
    @discardableResult
    public func unregister(_ name: String) -> Bool {
        let removed = tools.removeValue(forKey: name) != nil
        if removed {
            logger.debug("Unregistered tool: \(name)")
        }
        return removed
    }

    /// Remove all registered tools.
    public func unregisterAll() {
        tools.removeAll()
        logger.debug("Unregistered all tools")
    }
}
