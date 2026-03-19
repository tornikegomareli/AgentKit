#if canImport(AppKit)
import AppKit
#endif
import Foundation
import AgentKitCore

/// An MCP bundle that exposes clipboard read/write to the agent.
///
/// Available on macOS. On iOS, clipboard access requires UIKit which
/// is not imported by this module. Use the iOS-specific bundle or
/// implement your own with UIPasteboard.
public struct ClipboardBundle: MCPBundle {
    public let name = "Clipboard"

    public init() {}

    public func tools() async -> [AgentTool] {
        var result: [AgentTool] = []

        #if canImport(AppKit)
        result.append(AgentTool(
            name: "readClipboard",
            description: "Read the current text contents of the system clipboard.",
            parameters: []
        ) { _ in
            return NSPasteboard.general.string(forType: .string) ?? ""
        })

        result.append(AgentTool(
            name: "writeClipboard",
            description: "Write text to the system clipboard, replacing current contents.",
            parameters: [
                .string("text", description: "The text to copy", required: true)
            ]
        ) { params in
            let text = params["text"] as? String ?? ""
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            return "Copied to clipboard"
        })
        #endif

        return result
    }
}
