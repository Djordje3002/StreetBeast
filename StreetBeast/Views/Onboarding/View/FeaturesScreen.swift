import SwiftUI

struct FeaturesScreen: View {
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            Text(localization.localized("onboarding_features_title"))
                .font(DesignSystem.Typography.title)
                .foregroundColor(design.textColor)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                FeatureRow(
                    icon: "bolt.fill",
                    title: localization.localized("onboarding_features_1_title"),
                    description: localization.localized("onboarding_features_1_desc")
                )
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: localization.localized("onboarding_features_2_title"),
                    description: localization.localized("onboarding_features_2_desc")
                )
                FeatureRow(
                    icon: "trophy.fill",
                    title: localization.localized("onboarding_features_3_title"),
                    description: localization.localized("onboarding_features_3_desc")
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            Spacer()
            
            PrimaryActionButton(
                title: localization.localized("onboarding_get_started"),
                action: onNext,
                verticalPadding: DesignSystem.Spacing.md
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    @ObservedObject private var design = DesignSystem.shared

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(design.accentColor)
                .frame(width: 44, height: 44)
                .background(design.accentColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(design.textColor)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(design.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
