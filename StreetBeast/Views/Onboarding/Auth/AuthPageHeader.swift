import SwiftUI

struct AuthPageHeader: View {
    let title: String
    let subtitle: String

    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(design.accentColor)
                    .frame(width: 24, height: 4)

                Text(localization.localized("app_name"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)
                    .tracking(1.0)
            }

            Text(title)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(design.textColor)

            Text(subtitle)
                .font(DesignSystem.Typography.body)
                .foregroundColor(design.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AuthPageHeader(
        title: "Welcome Back",
        subtitle: "Sign in to continue your journey"
    )
    .padding()
    .background(StreetBeastBackground())
}
