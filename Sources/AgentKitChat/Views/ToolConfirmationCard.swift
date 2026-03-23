import SwiftUI
import LocalAuthentication
import AgentKitCore

/// Inline confirmation card displayed in the chat when a tool requires user approval.
///
/// Shows the tool name, a human-readable description of the action, and
/// Approve/Reject buttons. For biometric-tier tools, the Approve button
/// triggers Face ID / Touch ID before forwarding approval.
@available(iOS 17.0, macOS 14.0, *)
struct ToolConfirmationCard: View {
    let item: ChatItem
    let onApprove: (UUID) -> Void
    let onReject: (UUID) -> Void
    @Environment(\.chatConfiguration) private var config
    @State private var isAuthenticating = false
    @State private var authError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.body)
                    .foregroundStyle(.orange)
                Text("Action requires approval")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            // Tool name
            Text(item.pendingConfirmation?.toolName ?? "")
                .font(.caption.monospaced().weight(.medium))
                .foregroundStyle(config.accentColor)

            // Display message
            Text(item.content)
                .font(.subheadline)

            // Auth error
            if let authError {
                Text(authError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    guard let id = item.pendingConfirmation?.id else { return }
                    onReject(id)
                } label: {
                    Text("Reject")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    handleApprove()
                } label: {
                    HStack(spacing: 6) {
                        if isAuthenticating {
                            ProgressView()
                                .controlSize(.mini)
                        } else if item.pendingConfirmation?.requiresBiometric == true {
                            Image(systemName: "faceid")
                                .font(.caption)
                        }
                        Text(item.pendingConfirmation?.requiresBiometric == true ? "Approve with Face ID" : "Approve")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(config.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(isAuthenticating)
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func handleApprove() {
        guard let pending = item.pendingConfirmation else { return }

        if pending.requiresBiometric {
            isAuthenticating = true
            authError = nil
            authenticateBiometric { success in
                isAuthenticating = false
                if success {
                    onApprove(pending.id)
                } else {
                    authError = "Authentication failed. Try again or reject."
                }
            }
        } else {
            onApprove(pending.id)
        }
    }

    private func authenticateBiometric(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        // Try biometrics first (Face ID / Touch ID)
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Confirm agent action"
            ) { success, _ in
                DispatchQueue.main.async { completion(success) }
            }
            return
        }

        // Fall back to device passcode
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Confirm agent action"
            ) { success, _ in
                DispatchQueue.main.async { completion(success) }
            }
            return
        }

        #if targetEnvironment(simulator)
        // Simulator with no biometrics/passcode — approve directly for testing
        completion(true)
        #else
        completion(false)
        #endif
    }
}
