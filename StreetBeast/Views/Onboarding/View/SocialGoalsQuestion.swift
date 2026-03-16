import SwiftUI

struct SocialGoalsQuestion: View {
    @Binding var selectedGoals: Set<SocialGoal>
    @ObservedObject var design = DesignSystem.shared
    let onNext: () -> Void
    
    var body: some View {
        QuestionLayout(
            questionNumber: 4,
            question: LocalizationManager.shared.localized("onboarding_goals_question"),
            subtitle: LocalizationManager.shared.localized("onboarding_goals_subtitle")
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(SocialGoal.allCases, id: \.self) { goal in
                    OptionButton(
                        title: goal.localizedTitle,
                        isSelected: selectedGoals.contains(goal),
                        action: {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            Spacer()
            
            PrimaryActionButton(
                title: LocalizationManager.shared.localized("onboarding_continue"),
                action: onNext,
                isEnabled: !selectedGoals.isEmpty,
                verticalPadding: DesignSystem.Spacing.md,
                backgroundColor: selectedGoals.isEmpty ? Color.gray : design.accentColor
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
}
