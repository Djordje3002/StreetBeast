import SwiftUI
import UserNotifications

struct NotificationQuestion: View {
    @Binding var notificationEnabled: Bool
    @ObservedObject var design = DesignSystem.shared
    @State private var selectedPreference: NotificationPreference = .morning
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isSubmitting = false
    
    private let notificationService = NotificationService.shared
    let onComplete: () -> Void
    
    var body: some View {
        QuestionLayout(
            questionNumber: 6,
            question: LocalizationManager.shared.localized("onboarding_notif_question"),
            subtitle: LocalizationManager.shared.localized("onboarding_notif_subtitle")
        ) {
            VStack(spacing: DesignSystem.Spacing.lg) {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(NotificationPreference.allCases, id: \.self) { preference in
                        OptionButton(
                            title: preference.title,
                            isSelected: selectedPreference == preference,
                            action: { selectedPreference = preference }
                        )
                    }
                }
                
                if authorizationStatus == .denied && selectedPreference != .off {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text(LocalizationManager.shared.localized("onboarding_notif_denied"))
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(design.secondaryTextColor)
                            .multilineTextAlignment(.center)
                        
                        Button(LocalizationManager.shared.localized("onboarding_notif_open_settings")) {
                            notificationService.openAppNotificationSettings()
                        }
                        .font(DesignSystem.Typography.button)
                        .foregroundColor(design.accentColor)
                        .accessibilityHint(LocalizationManager.shared.localized("settings_open_link_hint"))
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .dynamicTypeSize(.medium ... .accessibility3)
            .task {
                await refreshAuthorizationState()
                if let savedPreference = notificationService.getPreference() {
                    selectedPreference = savedPreference
                    notificationEnabled = savedPreference != .off
                }
            }
            
            Spacer()
            
            PrimaryActionButton(
                title: LocalizationManager.shared.localized("onboarding_continue"),
                action: submit,
                isEnabled: !isSubmitting,
                verticalPadding: DesignSystem.Spacing.md
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
    
    private func submit() {
        guard !isSubmitting else { return }
        
        Task {
            await MainActor.run {
                isSubmitting = true
            }
            
            if selectedPreference == .off {
                notificationService.disableNotifications()
                await MainActor.run {
                    notificationEnabled = false
                    isSubmitting = false
                    onComplete()
                }
                return
            }
            
            let enabled = await notificationService.applyOnboardingPreference(selectedPreference)
            await refreshAuthorizationState()
            
            await MainActor.run {
                if !enabled {
                    selectedPreference = .off
                }
                notificationEnabled = enabled
                isSubmitting = false
                onComplete()
            }
        }
    }
    
    private func refreshAuthorizationState() async {
        let status = await notificationService.getAuthorizationStatus()
        await MainActor.run {
            authorizationStatus = status
        }
    }
}
