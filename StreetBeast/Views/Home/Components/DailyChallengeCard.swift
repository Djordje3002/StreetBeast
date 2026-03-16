import SwiftUI

struct DailyChallengeCard: View {
    let challenge: SocialChallenge
    let contentDate: String
    let isCompleted: Bool
    let onChallengeCompleted: (() -> Void)?
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(challenge.zone.color))
                        
                        Text(challenge.title(for: localization.currentLanguage))
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(design.textColor)
                    }
                }
                
                Spacer()
                
                // Difficulty Badge
                Text("\(localization.localized("home_level_short")) \(challenge.difficultyLevel)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(design.textColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(challenge.zone.color).opacity(0.82))
                    )
            }
            .padding(.horizontal)
            .padding(.top, 22)
            
            Divider()
                .background(design.accentColor.opacity(0.1))
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text(challenge.description(for: localization.currentLanguage))
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(design.secondaryTextColor)
                    .lineSpacing(4)
                    .padding(.bottom)
                
                // Action Button
                NavigationLink(destination: InteractiveChallengeView(challenge: challenge, onChallengeCompleted: onChallengeCompleted)) {
                    HStack {
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                            Text(localization.localized("home_challenge_completed"))
                        } else {
                            Image(systemName: "play.circle.fill")
                            Text(localization.localized("home_start_challenge"))
                        }
                    }
                    .font(DesignSystem.Typography.button)
                    .foregroundColor(design.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        isCompleted
                        ? Color.green
                        : design.accentColor
                    )
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .disabled(isCompleted)
                .opacity(isCompleted ? 0.8 : 1.0)
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .streetBeastSurface()
        .neonShadow(color: Color(challenge.zone.color).opacity(0.3), radius: 10)
    }
}

#Preview {
    NavigationStack {
        DailyChallengeCard(
            challenge: SocialChallenge.initialChallenges.first!,
            contentDate: "Jan 1, 2024",
            isCompleted: false,
            onChallengeCompleted: nil
        )
        .padding()
        .background(DesignSystem.shared.backgroundColor.ignoresSafeArea())
    }
}
