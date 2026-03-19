import Foundation

/// A callable tool that the agent can invoke during its reasoning loop.
///
/// Tools are the primary integration point between your app and the agent.
/// Register tools via ``ToolRegistry`` — AgentKit translates them to whatever
/// schema the active LLM expects.
///
/// The `description` is passed directly to the LLM. Write it as you would
/// write a function docstring for a colleague. Vague descriptions lead to
/// the agent calling tools at the wrong time or with wrong parameters.
///
/// ## Example
/// ```swift
/// AgentTool(
///     name: "searchProducts",
///     description: "Search the product catalog by keyword. Returns top results.",
///     parameters: [
///         .string("query", description: "Search term", required: true),
///         .int("limit", description: "Max results to return", required: false)
///     ]
/// ) { params in
///     let query = params["query"] as? String ?? ""
///     return await catalog.search(query)
/// }
/// ```
public struct AgentTool: Sendable {
    public let name: String
    public let description: String
    public let parameters: [ToolParameter]
    public let handler: @Sendable (SendableDictionary) async throws -> Any

    public init(
        name: String,
        description: String,
        parameters: [ToolParameter] = [],
        handler: @escaping @Sendable (SendableDictionary) async throws -> Any
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.handler = handler
    }
}
