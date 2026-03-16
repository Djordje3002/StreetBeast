import SwiftUI

struct StrengthFeedbackView: View {
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(design.accentColor.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(design.accentColor)
                    .shadow(color: design.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
            }

            VStack(spacing: DesignSystem.Spacing.md) {
                Text(localization.localized("onboarding_feedback_title"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)
                    .multilineTextAlignment(.center)

                Text(localization.localized("onboarding_feedback_subtitle"))
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(design.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                badgeRow(
                    icon: "star.fill",
                    title: localization.localized("onboarding_badge_title"),
                    description: localization.localized("onboarding_badge_subtitle")
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)

            Spacer()

            PrimaryActionButton(
                title: localization.localized("onboarding_continue"),
                action: onNext,
                verticalPadding: DesignSystem.Spacing.md
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .padding()
    }

    private func badgeRow(icon: String, title: String, description: String) -> some View {
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
    StrengthFeedbackView(onNext: {})
}
