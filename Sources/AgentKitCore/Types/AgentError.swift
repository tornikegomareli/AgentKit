import Foundation

/// Errors that can occur during agent operation.
///
/// All provider-specific errors are mapped to one of these cases by the
/// LLM adapters. Your error handling code never needs to know which
/// provider is active.
public enum AgentError: Error, Sendable {
    /// The requested LLM provider is not available (e.g. Apple on-device on iOS < 26).
    case providerUnavailable(String)

    /// The agent tried to call a tool that is not registered.
    case toolNotFound(String)

    /// A registered tool threw an error during execution.
    case toolExecutionFailed(String, Error)

    /// The conversation history exceeds the LLM's context window
    /// and cannot be compressed further.
    case contextWindowExceeded

    /// No network connection and no offline fallback configured.
    case networkUnavailable

    /// The agent loop reached its maximum iteration count without
    /// producing a final response. This prevents infinite tool call loops.
    case maxIterationsExceeded

    /// The operation was cancelled via structured concurrency.
    case cancelled

    /// An unexpected error from the provider or runtime.
    case unknown(Error)
}

extension AgentError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .providerUnavailable(let reason):
            return "Provider unavailable: \(reason)"
        case .toolNotFound(let name):
            return "Tool not found: \(name)"
        case .toolExecutionFailed(let name, let error):
            return "Tool '\(name)' failed: \(error)"
        case .contextWindowExceeded:
            return "Context window exceeded"
        case .networkUnavailable:
            return "Network unavailable"
        case .maxIterationsExceeded:
            return "Max iterations exceeded"
        case .cancelled:
            return "Operation cancelled"
        case .unknown(let error):
            return "Unknown error: \(error)"
        }
    }
}


