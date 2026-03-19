import SwiftUI
import AgentKitCore

// MARK: - AgentChatView placeholder
// Full implementation will be added in Phase 3.

/// Placeholder to allow the package to compile.
/// Phase 3 will implement the full drop-in chat view.
@available(iOS 17.0, macOS 14.0, *)
public struct AgentChatView: View {
    private let session: AgentSession

    public init(session: AgentSession) {
        self.session = session
    }

    public var body: some View {
        Text("AgentKit Chat — Coming in Phase 3")
    }
}
