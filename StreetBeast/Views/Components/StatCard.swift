import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    @ObservedObject private var design = DesignSystem.shared

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.16))
                    .clipShape(Circle())
            }

            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(design.textColor)

            Text(subtitle)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(design.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.lg)
        .streetBeastSurface()
    }
}

#Preview {
    StatCard(
        title: "Current Streak",
        value: "12",
        subtitle: "Days",
        icon: "flame.fill",
        color: .orange
    )
    .padding()
}
