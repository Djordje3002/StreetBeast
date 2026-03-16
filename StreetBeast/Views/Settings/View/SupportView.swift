import SwiftUI

struct SupportView: View {
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack(alignment: .top) {
            StreetBeastBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        heroCard
                        contactSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.lg)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
        .dynamicTypeSize(.medium ... .accessibility3)
    }
}

private extension SupportView {
    var header: some View {
        ScreenHeader(
            title: localization.localized("support_title"),
            leading: {
                HeaderBackButton(
                    accessibilityLabel: localization.localized("a11y_back"),
                    accessibilityHint: localization.localized("a11y_back_hint"),
                    action: { dismiss() }
                )
            },
            trailing: { EmptyView() },
            bottom: { EmptyView() }
        )
    }

    var heroCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [design.accentColor.opacity(0.25), design.accentColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 76, height: 76)

                Image(systemName: "lifepreserver.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(design.accentColor)
            }

            Text(localization.localized("support_title"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(design.textColor)

            Text(localization.localized("support_subtitle"))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(design.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
        .settingsCardSurface()
    }

    var contactSection: some View {
        SectionBlock(title: localization.localized("support_contact_section")) {
            SettingsCardGroup {
                Button(action: openSupportEmail) {
                    SettingsListRow(icon: "envelope.fill", title: localization.localized("support_email_label")) {
                        Text(AppLinks.supportEmail)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(design.secondaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint(localization.localized("support_email_hint"))

                SettingsRowDivider()
            }
        }
    }

    func openSupportEmail() {
        guard let mailURL = URL(string: "mailto:\(AppLinks.supportEmail)") else { return }
        openURL(mailURL)
    }
}

#Preview {
    NavigationView {
        SupportView()
    }
}
