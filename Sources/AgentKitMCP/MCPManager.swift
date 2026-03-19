import Foundation
import AgentKitCore
import os.log

/// Manages MCP (Model Context Protocol) tool bundles and their registration
/// into the agent's ``ToolRegistry``.
///
/// MCP bundles expose system APIs (Calendar, Reminders, Contacts, etc.)
/// as agent tools. The manager handles discovery, permission requests,
/// and auto-registration.
///
/// ## Example
/// ```swift
/// let mcp = MCPManager()
/// mcp.registerBundle(.calendar)
/// mcp.registerBundle(.reminders)
/// await mcp.installTools(into: agent.tools)
/// ```
public final class MCPManager: Sendable {
    private let logger = Logger(subsystem: "com.agentkit.mcp", category: "MCPManager")
    private let bundles: LockedBox<[MCPBundle]> = LockedBox([])

    public init() {}

    /// Register a bundle for installation.
    public func registerBundle(_ bundle: MCPBundle) {
        bundles.mutate { $0.append(bundle) }
        logger.debug("Registered MCP bundle: \(bundle.name)")
    }

    /// Install all registered bundles' tools into the given registry.
    public func installTools(into registry: ToolRegistry) async {
        let currentBundles = bundles.value
        for bundle in currentBundles {
            let tools = await bundle.tools()
            for tool in tools {
                await registry.register(
                    name: tool.name,
                    description: tool.description,
                    parameters: tool.parameters,
                    handler: tool.handler
                )
            }
            logger.debug("Installed \(tools.count) tools from bundle: \(bundle.name)")
        }
    }
}

// MARK: - MCP Bundle Protocol

/// A bundle of tools that expose a system API to the agent.
///
/// Implement this protocol to create custom MCP bundles.
/// Built-in bundles (Calendar, Reminders, etc.) will be added in future releases.
public protocol MCPBundle: Sendable {
    /// Human-readable name of this bundle.
    var name: String { get }

    /// The tools this bundle provides.
    func tools() async -> [AgentTool]
}

// MARK: - Thread-safe box

final class LockedBox<Value: Sendable>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self._value = value
    }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func mutate(_ transform: (inout Value) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        transform(&_value)
    }
}
