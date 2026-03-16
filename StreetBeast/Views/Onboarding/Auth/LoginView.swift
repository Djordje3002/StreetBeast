import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var acceptedTerms = false
    @State private var acceptedPrivacy = false
    @State private var showPasswordReset = false
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var toastManager = ToastManager.shared
    @ObservedObject var localization = LocalizationManager.shared
    
    let onSignUp: () -> Void
    
    var body: some View {
        ZStack {
            StreetBeastBackground()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 42)

                    AuthPageHeader(
                        title: localization.localized("auth_welcome_back"),
                        subtitle: localization.localized("auth_sign_in_subtitle")
                    )
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.bottom, DesignSystem.Spacing.xl)
                    
                    // Form
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Email field
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(localization.localized("auth_email"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(design.secondaryTextColor)
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            TextField(localization.localized("auth_enter_email"), text: $email)
                                .textFieldStyle(ModernTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                                .accessibilityLabel(localization.localized("a11y_email"))
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(localization.localized("auth_password"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(design.secondaryTextColor)
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            SecureField(localization.localized("auth_enter_password"), text: $password)
                                .textFieldStyle(ModernTextFieldStyle())
                                .textContentType(.password)
                                .accessibilityLabel(localization.localized("a11y_password"))
                        }
                        
                        // Remember me and forgot password
                        HStack {
                            Button(action: { rememberMe.toggle() }) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .foregroundColor(rememberMe ? design.accentColor : design.secondaryTextColor)
                                    
                                    Text(localization.localized("auth_remember_me"))
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(design.textColor)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: { showPasswordReset = true }) {
                                Text(localization.localized("auth_forgot_password"))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(design.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.top, DesignSystem.Spacing.xs)

                        AuthLegalConsentSection(
                            acceptedTerms: $acceptedTerms,
                            acceptedPrivacy: $acceptedPrivacy
                        )
                        
                        // Login button
                        Button(action: handleLogin) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(localization.localized("auth_sign_in"))
                                        .font(DesignSystem.Typography.button)
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(
                                LinearGradient(
                                    colors: isSubmissionEnabled ? [design.accentColor, design.accentColor.opacity(0.8)] : [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .shadow(
                                color: isSubmissionEnabled ? design.accentColor.opacity(0.3) : .clear,
                                radius: isSubmissionEnabled ? 15 : 0,
                                x: 0,
                                y: isSubmissionEnabled ? 8 : 0
                            )
                        }
                        .disabled(authManager.isLoading || !isSubmissionEnabled)
                        .accessibilityLabel(localization.localized("auth_sign_in"))
                        .accessibilityHint(localization.localized("a11y_sign_in_hint"))
                        .padding(.top, DesignSystem.Spacing.md)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(design.secondaryTextColor.opacity(0.3))
                                .frame(height: 1)
                            
                            Text(localization.localized("auth_or"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(design.secondaryTextColor)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            Rectangle()
                                .fill(design.secondaryTextColor.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, DesignSystem.Spacing.lg)
                        
                        // Sign up link
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text(localization.localized("auth_no_account"))
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(design.secondaryTextColor)
                            
                            Button(action: onSignUp) {
                                Text(localization.localized("auth_sign_up"))
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(design.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    Spacer(minLength: 48)
                }
            }
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView()
        }
        .onAppear {
            // Load saved email if "remember me" was checked
            if let savedEmail = UserDefaults.standard.string(forKey: "savedEmail") {
                email = savedEmail
                rememberMe = true
            }
        }
        .dynamicTypeSize(.medium ... .accessibility3)
    }
    
    private var isCredentialsValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }

    private var isSubmissionEnabled: Bool {
        isCredentialsValid && acceptedTerms && acceptedPrivacy
    }
    
    private func handleLogin() {
        guard isCredentialsValid else { return }
        guard acceptedTerms && acceptedPrivacy else {
            toastManager.show(localization.localized("auth_legal_required_error"), type: .error)
            return
        }
        
        Task {
            await authManager.login(email: email, password: password)
            
            if let error = authManager.error {
                await MainActor.run {
                    toastManager.show(error.localizedDescription, type: .error)
                }
            }
            
            if rememberMe {
                UserDefaults.standard.set(email, forKey: "savedEmail")
            } else {
                UserDefaults.standard.removeObject(forKey: "savedEmail")
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView(onSignUp: { })
    }
}
