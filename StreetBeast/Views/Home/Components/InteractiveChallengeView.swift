import SwiftUI

struct InteractiveChallengeView: View {
    let challenge: SocialChallenge
    let onChallengeCompleted: (() -> Void)?
    
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var localization = LocalizationManager.shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isCompleted = false
    @State private var animatePulse = false
    @State private var animateEntrance = false
    @State private var hasNotifiedCompletion = false
    
    private let challengeService = ChallengeService.shared
    
    init(challenge: SocialChallenge, onChallengeCompleted: (() -> Void)? = nil) {
        self.challenge = challenge
        self.onChallengeCompleted = onChallengeCompleted
    }
    
    var body: some View {
        ZStack {
            design.backgroundColor
                .ignoresSafeArea()
            
            if isCompleted {
                completionView
            } else {
                challengeReadyView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(design.textColor)
                }
            }
        }
    }
    
    private var challengeReadyView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text(challenge.title(for: localization.currentLanguage))
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(design.textColor)
                    .multilineTextAlignment(.center)
                
                Text(challenge.description(for: localization.currentLanguage))
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(design.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            
            Spacer()
            
            PrimaryActionButton(
                title: localization.localized("home_mark_challenge_completed"),
                action: { handleCompletion() }
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
            .padding(.bottom, 52)
        }
    }
    
    // MARK: - Completion Content
    
    private var completionView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            successIcon
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text(localization.localized("home_challenge_completed"))
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(design.textColor)
                
                Text(challenge.title(for: localization.currentLanguage))
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(design.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
            .opacity(animateEntrance ? 1 : 0)
            .offset(y: animateEntrance ? 0 : 12)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateEntrance)
            
            Spacer()
            
            PrimaryActionButton(
                title: localization.localized("home_back_to_home"),
                action: { dismiss() }
            )
            .shadow(color: design.accentColor.opacity(0.3), radius: 10, y: 4)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
            .padding(.bottom, 52)
        }
    }
    
    // MARK: - Success Icon
    
    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0.35),
                            Color.blue.opacity(0.35)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 130, height: 130)
                .shadow(color: Color.green.opacity(0.25),
                        radius: 20, y: 8)
            
            Image(systemName: "checkmark")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.green)
        }
        .scaleEffect(animatePulse ? 1.08 : 0.95)
        .opacity(animateEntrance ? 1 : 0)
        .animation(
            .easeInOut(duration: 1.4)
                .repeatForever(autoreverses: true),
            value: animatePulse
        )
        .animation(
            .spring(response: 0.5, dampingFraction: 0.6),
            value: animateEntrance
        )
    }
    
    // MARK: - Logic
    
    private func handleCompletion() {
        guard !isCompleted else { return }
        
        if !challengeService.isChallengeCompleted(id: challenge.id) {
            challengeService.completeChallenge(id: challenge.id)
        }
        
        if !hasNotifiedCompletion {
            hasNotifiedCompletion = true
            onChallengeCompleted?()
        }
        
        isCompleted = true
        
        // Entrance animation
        animateEntrance = true
        
        // Start pulse slightly delayed for polish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animatePulse = true
        }
        
        // Optional haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    InteractiveChallengeView(
        challenge: SocialChallenge.initialChallenges.first!,
        onChallengeCompleted: nil
    )
}
