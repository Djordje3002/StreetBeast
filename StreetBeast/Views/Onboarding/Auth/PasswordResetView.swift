import SwiftUI
import FirebaseAuth

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isSubmitting = false
    @State private var didSend = false
    @State private var errorMessage: String?

    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    private var isEmailValid: Bool {
        email.contains("@")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StreetBeastBackground()

                VStack(spacing: DesignSystem.Spacing.lg) {
                    Text(localization.localized("auth_reset_password"))
                        .font(DesignSystem.Typography.title)
                        .foregroundColor(design.textColor)
                        .multilineTextAlignment(.center)

                    Text(localization.localized("auth_reset_subtitle"))
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(design.secondaryTextColor)
                        .multilineTextAlignment(.center)

                    TextField(localization.localized("auth_enter_email"), text: $email)
                        .textFieldStyle(ModernTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .disabled(didSend || isSubmitting)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if didSend {
                        Text(localization.localized("auth_reset_success"))
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(design.accentColor)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: {
                        if didSend {
                            MainActor.assumeIsolated {
                                dismiss()
                            }
                        } else {
                            sendResetLink()
                        }
                    }) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(didSend ? localization.localized("auth_done") : localization.localized("auth_send_reset_link"))
                                    .font(DesignSystem.Typography.button)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(
                            LinearGradient(
                                colors: actionButtonColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    .disabled((!didSend && (!isEmailValid || isSubmitting)))
                    .padding(.top, DesignSystem.Spacing.sm)

                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.top, DesignSystem.Spacing.xl)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.localized("cancel")) {
                        dismiss()
                    }
                    .foregroundColor(design.accentColor)
                }
            }
        }
        .dynamicTypeSize(.medium ... .accessibility3)
    }

    private var actionButtonColors: [Color] {
        if didSend {
            return [design.accentColor, design.accentColor.opacity(0.8)]
        }
        if !isEmailValid {
            return [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]
        }
        return [design.accentColor, design.accentColor.opacity(0.8)]
    }

    private func sendResetLink() {
        guard isEmailValid, !isSubmitting else { return }
        errorMessage = nil
        isSubmitting = true

        Task {
            do {
                try await sendPasswordReset(email: email)
                await MainActor.run {
                    didSend = true
                    isSubmitting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }

    private func sendPasswordReset(email: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

#Preview {
    PasswordResetView()
}
