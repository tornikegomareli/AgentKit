import Foundation

/// Describes a single parameter accepted by an ``AgentTool``.
///
/// Parameter definitions are passed to the active LLM as part of the tool schema.
/// Well-described parameters significantly improve the model's ability to call
/// tools with correct arguments. Write descriptions as you would write a function
/// docstring for a colleague.
public enum ToolParameter: Sendable {
    case string(_ name: String, description: String, required: Bool = true)
    case int(_ name: String, description: String, required: Bool = false)
    case bool(_ name: String, description: String, required: Bool = false)
    case object(_ name: String, description: String, required: Bool = false)
    case array(_ name: String, description: String, required: Bool = false)
    case number(_ name: String, description: String, required: Bool = false)

    /// The parameter name used as the key in tool call arguments.
    public var name: String {
        switch self {
        case .string(let name, _, _),
             .int(let name, _, _),
             .bool(let name, _, _),
             .object(let name, _, _),
             .array(let name, _, _),
             .number(let name, _, _):
            return name
        }
    }

    /// A plain-English description of the parameter's purpose.
    public var description: String {
        switch self {
        case .string(_, let description, _),
             .int(_, let description, _),
             .bool(_, let description, _),
             .object(_, let description, _),
             .array(_, let description, _),
             .number(_, let description, _):
            return description
        }
    }

    /// Whether the LLM must provide this parameter when calling the tool.
    public var isRequired: Bool {
        switch self {
        case .string(_, _, let required),
             .int(_, _, let required),
             .bool(_, _, let required),
             .object(_, _, let required),
             .array(_, _, let required),
             .number(_, _, let required):
            return required
        }
    }

    /// The JSON Schema type name for this parameter.
    public var typeName: String {
        switch self {
        case .string: return "string"
        case .int: return "integer"
        case .bool: return "boolean"
        case .object: return "object"
        case .array: return "array"
        case .number: return "number"
        }
    }
}
