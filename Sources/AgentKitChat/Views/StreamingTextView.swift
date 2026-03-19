import SwiftUI

/// Displays streaming text with a blinking cursor at the end.
@available(iOS 17.0, macOS 14.0, *)
struct StreamingTextView: View {
    let text: String
    @State private var cursorVisible = true

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(text)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
            if !text.isEmpty {
                Text("|")
                    .foregroundStyle(.secondary)
                    .opacity(cursorVisible ? 1 : 0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                        value: cursorVisible
                    )
                    .onAppear { cursorVisible = false }
            }
        }
    }
}
