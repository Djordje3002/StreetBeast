import SwiftUI

struct FocusAreaQuestion: View {
    @Binding var selectedAreas: Set<String>
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    let onNext: () -> Void

    private let focusAreaKeys: [String] = [
        "onboarding_focus_1",
        "onboarding_focus_2",
        "onboarding_focus_3",
        "onboarding_focus_4",
        "onboarding_focus_5",
        "onboarding_focus_6",
        "onboarding_focus_7",
        "onboarding_focus_8"
    ]

    var body: some View {
        QuestionLayout(
            questionNumber: 5,
            question: localization.localized("onboarding_focus_question"),
            subtitle: localization.localized("onboarding_focus_subtitle")
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(focusAreaKeys, id: \.self) { areaKey in
                    OptionButton(
                        title: localization.localized(areaKey),
                        isSelected: selectedAreas.contains(areaKey),
                        action: {
                            if selectedAreas.contains(areaKey) {
                                selectedAreas.remove(areaKey)
                            } else {
                                selectedAreas.insert(areaKey)
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
                isEnabled: !selectedAreas.isEmpty,
                verticalPadding: DesignSystem.Spacing.md,
                backgroundColor: selectedAreas.isEmpty ? .gray : design.accentColor
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
}

#Preview {
    FocusAreaQuestion(selectedAreas: .constant(["onboarding_focus_1"]), onNext: {})
}
