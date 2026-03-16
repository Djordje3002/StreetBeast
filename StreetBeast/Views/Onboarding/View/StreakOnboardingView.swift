import SwiftUI

struct StreakOnboardingView: View {
    @ObservedObject var design = DesignSystem.shared
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Animated Flame Icon
            ZStack {
                Circle()
                    .fill(design.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [design.accentColor, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text(LocalizationManager.shared.localized("onboarding_streak_title"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)
                    .multilineTextAlignment(.center)
                
                Text(LocalizationManager.shared.localized("onboarding_streak_subtitle"))
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(design.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                streakDetailRow(
                    icon: "calendar.badge.plus",
                    title: LocalizationManager.shared.localized("onboarding_streak_1_title"),
                    description: LocalizationManager.shared.localized("onboarding_streak_1_desc")
                )
                
                streakDetailRow(
                    icon: "timer",
                    title: LocalizationManager.shared.localized("onboarding_streak_2_title"),
                    description: LocalizationManager.shared.localized("onboarding_streak_2_desc")
                )
                
                streakDetailRow(
                    icon: "trophy.fill",
                    title: LocalizationManager.shared.localized("onboarding_streak_3_title"),
                    description: LocalizationManager.shared.localized("onboarding_streak_3_desc")
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            Spacer()
            
            PrimaryActionButton(
                title: LocalizationManager.shared.localized("onboarding_continue"),
                action: onNext,
                verticalPadding: DesignSystem.Spacing.md
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .padding()
    }
    
    private func streakDetailRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(design.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(design.secondaryTextColor)
                    .lineSpacing(2)
            }
        }
    }
}

#Preview {
    StreakOnboardingView(onNext: {})
}
