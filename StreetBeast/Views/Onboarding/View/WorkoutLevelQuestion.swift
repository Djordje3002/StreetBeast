import SwiftUI

struct WorkoutLevelQuestion: View {
    @Binding var selectedLevel: WorkoutLevel?
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    let onNext: () -> Void

    var body: some View {
        QuestionLayout(
            questionNumber: 3,
            question: localization.localized("onboarding_level_title"),
            subtitle: localization.localized("onboarding_level_subtitle")
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(WorkoutLevel.allCases, id: \.self) { level in
                    OptionButton(
                        title: level.localizedTitle,
                        isSelected: selectedLevel == level,
                        action: {
                            if selectedLevel == level {
                                selectedLevel = nil
                            } else {
                                selectedLevel = level
                            }
                        }
                    )
                }
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
    }
}

#Preview {
    WorkoutLevelQuestion(selectedLevel: .constant(.beginner), onNext: {})
}
