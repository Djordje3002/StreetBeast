import SwiftUI

struct NameQuestion: View {
    @Binding var name: String
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    let onNext: () -> Void

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        QuestionLayout(
            questionNumber: 2,
            question: localization.localized("onboarding_name_title"),
            subtitle: localization.localized("onboarding_name_subtitle")
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(localization.localized("onboarding_name_label"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(design.secondaryTextColor)
                        .textCase(.uppercase)
                        .tracking(1)

                    TextField(localization.localized("onboarding_name_placeholder"), text: $name)
                        .textFieldStyle(ModernTextFieldStyle())
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel(localization.localized("onboarding_name_label"))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)

            Spacer()

            PrimaryActionButton(
                title: localization.localized("onboarding_continue"),
                action: {
                    name = trimmedName
                    onNext()
                },
                isEnabled: !trimmedName.isEmpty,
                verticalPadding: DesignSystem.Spacing.md,
                backgroundColor: trimmedName.isEmpty ? .gray : design.accentColor
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
}

#Preview {
    NameQuestion(name: .constant("Djordje"), onNext: {})
}
