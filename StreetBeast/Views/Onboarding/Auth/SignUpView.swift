import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var acceptedTerms = false
    @State private var acceptedPrivacy = false
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var toastManager = ToastManager.shared
    @ObservedObject var localization = LocalizationManager.shared
    
    let onLogin: () -> Void
    
    var body: some View {
        ZStack {
            StreetBeastBackground()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 34)

                    AuthPageHeader(
                        title: localization.localized("auth_create_account"),
                        subtitle: localization.localized("auth_create_subtitle")
                    )
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.bottom, DesignSystem.Spacing.lg)
                    
                    // Form
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Name field
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(localization.localized("auth_name_optional"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(design.secondaryTextColor)
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            TextField(localization.localized("auth_enter_name"), text: $name)
                                .textFieldStyle(ModernTextFieldStyle())
                                .textContentType(.name)
                                .accessibilityLabel(localization.localized("a11y_name"))
                        }
                        
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
                            
                            HStack {
                                if showPassword {
                                    TextField(localization.localized("auth_create_password"), text: $password)
                                        .textContentType(.newPassword)
                                        .accessibilityLabel(localization.localized("a11y_create_password"))
                                } else {
                                    SecureField(localization.localized("auth_create_password"), text: $password)
                                        .textContentType(.newPassword)
                                        .accessibilityLabel(localization.localized("a11y_create_password"))
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(design.secondaryTextColor)
                                }
                            }
                            .padding()
                            .background(design.paperColor)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(design.secondaryTextColor.opacity(0.2), lineWidth: 1)
                            )
                            .foregroundColor(design.textColor)
                            
                            if !password.isEmpty {
                                PasswordStrengthIndicator(password: password)
                                    .padding(.top, DesignSystem.Spacing.xs)
                            }
                        }
                        
                        // Confirm Password field
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(localization.localized("auth_confirm_password"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(design.secondaryTextColor)
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            HStack {
                                if showConfirmPassword {
                                    TextField(localization.localized("auth_confirm_password_placeholder"), text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .accessibilityLabel(localization.localized("a11y_confirm_password"))
                                } else {
                                    SecureField(localization.localized("auth_confirm_password_placeholder"), text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .accessibilityLabel(localization.localized("a11y_confirm_password"))
                                }
                                
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(design.secondaryTextColor)
                                }
                            }
                            .padding()
                            .background(design.paperColor)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(passwordMatch ? design.accentColor.opacity(0.5) : design.secondaryTextColor.opacity(0.2), lineWidth: passwordMatch && !confirmPassword.isEmpty ? 2 : 1)
                            )
                            .foregroundColor(design.textColor)
                            
                            if !confirmPassword.isEmpty && !passwordMatch {
                                Text(localization.localized("auth_password_mismatch"))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, DesignSystem.Spacing.xs)
                            }
                        }

                        AuthLegalConsentSection(
                            acceptedTerms: $acceptedTerms,
                            acceptedPrivacy: $acceptedPrivacy
                        )
                        
                        // Sign up button
                        Button(action: handleSignUp) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(localization.localized("auth_create_account"))
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
                        .accessibilityLabel(localization.localized("auth_create_account"))
                        .accessibilityHint(localization.localized("a11y_create_account_hint"))
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
                        
                        // Login link
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text(localization.localized("auth_have_account"))
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(design.secondaryTextColor)
                            
                            Button(action: onLogin) {
                                Text(localization.localized("auth_sign_in"))
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
        .dynamicTypeSize(.medium ... .accessibility3)
    }
    
    private var passwordMatch: Bool {
        password == confirmPassword || confirmPassword.isEmpty
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }

    private var isSubmissionEnabled: Bool {
        isFormValid && acceptedTerms && acceptedPrivacy
    }
    
    private func handleSignUp() {
        guard isFormValid else {
            if password.count < 6 {
                toastManager.show(localization.localized("auth_password_min_error"), type: .error)
            } else if password != confirmPassword {
                toastManager.show(localization.localized("auth_password_mismatch_error"), type: .error)
            }
            return
        }
        guard acceptedTerms && acceptedPrivacy else {
            toastManager.show(localization.localized("auth_legal_required_error"), type: .error)
            return
        }
        
        Task {
            await authManager.register(email: email, password: password, name: name.isEmpty ? nil : name)
            
            if let error = authManager.error {
                await MainActor.run {
                    toastManager.show(error.localizedDescription, type: .error)
                }
            } else {
                await MainActor.run {
                    toastManager.show(localization.localized("auth_signup_success"), type: .success)
                }
            }
        }
    }
}
