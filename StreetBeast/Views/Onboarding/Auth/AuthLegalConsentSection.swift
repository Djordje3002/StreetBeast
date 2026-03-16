import SwiftUI

struct AuthLegalConsentSection: View {
    @Binding var acceptedTerms: Bool
    @Binding var acceptedPrivacy: Bool

    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            consentRow(
                isChecked: $acceptedTerms,
                linkTitle: localization.localized("terms_of_service"),
                linkURL: AppLinks.termsOfService
            )

            consentRow(
                isChecked: $acceptedPrivacy,
                linkTitle: localization.localized("privacy_policy"),
                linkURL: AppLinks.privacyPolicy
            )
        }
    }

    private func consentRow(
        isChecked: Binding<Bool>,
        linkTitle: String,
        linkURL: String
    ) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
            Button {
                isChecked.wrappedValue.toggle()
            } label: {
                Image(systemName: isChecked.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isChecked.wrappedValue ? design.accentColor : design.secondaryTextColor)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 0) {
                Text(localization.localized("auth_i_agree_to"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(design.textColor)

                if let url = URL(string: linkURL) {
                    Link(linkTitle, destination: url)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(design.accentColor)
                } else {
                    Text(linkTitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(design.accentColor)
                }
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AuthLegalConsentSection(
        acceptedTerms: .constant(false),
        acceptedPrivacy: .constant(true)
    )
    .padding()
    .background(DesignSystem.shared.backgroundColor)
}
