import SwiftUI

struct WalkthroughScreen: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let onNext: () -> Void

    @ObservedObject private var design = DesignSystem.shared

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(design.accentColor.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundColor(design.accentColor)
            }

            VStack(spacing: DesignSystem.Spacing.md) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(design.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }

            Spacer()

            PrimaryActionButton(
                title: buttonTitle,
                action: onNext,
                verticalPadding: DesignSystem.Spacing.md
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .padding()
    }
}

#Preview {
    WalkthroughScreen(
        icon: "timer",
        title: "Train with structured workouts.",
        subtitle: "Start workouts with automatic timers that guide you through exercises and rest periods.",
        buttonTitle: "Continue",
        onNext: {}
    )
}
