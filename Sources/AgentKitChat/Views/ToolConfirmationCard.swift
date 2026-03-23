import SwiftUI
import LocalAuthentication
import AgentKitCore

/// Default confirmation sheet content shown when a tool requires user approval.
///
/// Developers can replace this with a custom view using the
/// `.confirmationView` modifier on ``AgentChatView``.
@available(iOS 17.0, macOS 14.0, *)
public struct ToolConfirmationSheet: View {
    public let confirmation: PendingToolConfirmation
    public let onApprove: () -> Void
    public let onReject: () -> Void
    @State private var isAuthenticating = false
    @State private var authFailed = false

    public init(
        confirmation: PendingToolConfirmation,
        onApprove: @escaping () -> Void,
        onReject: @escaping () -> Void
    ) {
        self.confirmation = confirmation
        self.onApprove = onApprove
        self.onReject = onReject
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Handle bar
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: confirmation.requiresBiometric ? "lock.shield.fill" : "checkmark.shield.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
            }

            // Title
            VStack(spacing: 6) {
                Text("Confirm Action")
                    .font(.title3.weight(.bold))
                Text(confirmation.toolName)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            // Description
            if let message = confirmation.displayMessage {
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if confirmation.requiresBiometric {
                HStack(spacing: 6) {
                    Image(systemName: "faceid")
                        .font(.caption)
                    Text("Biometric authentication required")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            // Auth error
            if authFailed {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text("Authentication failed. Try again.")
                        .font(.caption)
                }
                .foregroundStyle(.red)
            }

            Spacer()

            // Buttons
            VStack(spacing: 10) {
                Button {
                    handleApprove()
                } label: {
                    HStack(spacing: 8) {
                        if isAuthenticating {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else if confirmation.requiresBiometric {
                            Image(systemName: "faceid")
                                .font(.body)
                        }
                        Text(confirmation.requiresBiometric ? "Approve with Face ID" : "Approve")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(isAuthenticating)

                Button {
                    onReject()
                } label: {
                    Text("Reject")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private func handleApprove() {
        authFailed = false

        if confirmation.requiresBiometric {
            isAuthenticating = true
            authenticateBiometric { success in
                isAuthenticating = false
                if success {
                    onApprove()
                } else {
                    authFailed = true
                }
            }
        } else {
            onApprove()
        }
    }

    private func authenticateBiometric(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Confirm agent action"
            ) { success, _ in
                DispatchQueue.main.async { completion(success) }
            }
            return
        }

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
        completion(true)
        #else
        completion(false)
        #endif
    }
}
