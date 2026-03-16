import SwiftUI

struct WidgetOnboardingView: View {
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var localization = LocalizationManager.shared
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Illustration Area
            ZStack {
                // Background "Home Screen" representation
                RoundedRectangle(cornerRadius: 32)
                    .fill(design.backgroundColor)
                    .frame(width: 260, height: 260)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                
                // Mock App Icons
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        mockIcon(color: .blue)
                        mockIcon(color: .green)
                        mockIcon(color: .orange)
                    }
                    
                    // The Widget
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(localization.localized("app_name"))
                                .font(DesignSystem.Typography.caption.weight(.bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text(String(format: localization.localized("onboarding_widget_preview_streak_format"), 5))
                                .font(DesignSystem.Typography.caption.weight(.bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(localization.localized("onboarding_widget_preview_challenge"))
                            .font(DesignSystem.Typography.body.weight(.semibold))
                            .lineLimit(1)
                            .foregroundColor(.white)
                        
                        Text(String(format: localization.localized("onboarding_widget_preview_level_format"), 1))
                            .font(DesignSystem.Typography.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                    .padding(12)
                    .frame(width: 160, height: 100)
                    .background(design.paperColor)
                    .cornerRadius(20)
                    .shadow(color: design.accentColor.opacity(0.2), radius: 10, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(design.accentColor.opacity(0.2), lineWidth: 1)
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        String(
                            format: localization.localized("onboarding_widget_preview_accessibility"),
                            localization.localized("onboarding_widget_preview_challenge"),
                            5,
                            1
                        )
                    )
                    
                    HStack(spacing: 20) {
                        mockIcon(color: .purple)
                        mockIcon(color: .red)
                        mockIcon(color: .teal)
                    }
                }
            }
            .padding(.top, 40)
            
            // Text Content
            VStack(spacing: DesignSystem.Spacing.md) {
                Text(localization.localized("onboarding_widget_title"))
                    .font(.title.bold())
                    .fontDesign(.rounded)
                    .foregroundColor(design.textColor)
                    .multilineTextAlignment(.center)
                
                Text(localization.localized("onboarding_widget_subtitle"))
                    .font(.body)
                    .foregroundColor(design.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .lineLimit(nil)
            }
            
            Spacer()
            
            // Action Button
            PrimaryActionButton(action: onComplete) {
                HStack {
                    Text(localization.localized("onboarding_get_started"))
                    Image(systemName: "arrow.right")
                }
            }
            .shadow(color: design.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
            .accessibilityHint(localization.localized("welcome_get_started_hint"))
        }
        .background(design.backgroundColor.ignoresSafeArea())
        .dynamicTypeSize(.medium ... .accessibility3)
        .accessibilityElement(children: .contain)
    }
    
    private func mockIcon(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(color.opacity(0.3))
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)
    }
}

#Preview {
    WidgetOnboardingView(onComplete: {})
}
