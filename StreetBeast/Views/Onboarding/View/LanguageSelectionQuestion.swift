import SwiftUI

struct LanguageSelectionQuestion: View {
    @ObservedObject var localization = LocalizationManager.shared
    let onNext: () -> Void
    
    var body: some View {
        QuestionLayout(
            questionNumber: 1,
            question: localization.localized("onboarding_language_title"),
            subtitle: localization.localized("onboarding_language_subtitle")
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(Language.allCases, id: \.self) { language in
                    LanguageOptionButton(
                        language: language,
                        isSelected: localization.currentLanguage == language,
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                localization.currentLanguage = language
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
    LanguageSelectionQuestion(onNext: {})
}
