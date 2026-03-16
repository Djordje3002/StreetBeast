import SwiftUI

struct ConfidenceLevelQuestion: View {
    @Binding var selectedLevel: ConfidenceLevel
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    let onNext: () -> Void

    var body: some View {
        QuestionLayout(
            questionNumber: 3,
            question: localization.localized("onboarding_confidence_question"),
            subtitle: localization.localized("onboarding_confidence_subtitle")
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(ConfidenceLevel.allCases, id: \.self) { level in
                    OptionButton(
                        title: level.localizedTitle,
                        isSelected: selectedLevel == level,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
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
                verticalPadding: DesignSystem.Spacing.md,
                backgroundColor: design.accentColor
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
}

#Preview {
    ConfidenceLevelQuestion(selectedLevel: .constant(.somewhatAnxious), onNext: {})
}
