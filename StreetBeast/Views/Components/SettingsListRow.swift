import SwiftUI

struct SettingsListRow<Accessory: View>: View {
    let icon: String
    let title: String
    var isSelected: Bool
    var accessory: Accessory

    @ObservedObject private var design = DesignSystem.shared

    init(
        icon: String,
        title: String,
        isSelected: Bool = false,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .white : design.accentColor)
                .frame(width: 32, height: 32)
                .background(isSelected ? .white.opacity(0.2) : design.accentColor.opacity(0.1))
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : design.textColor)

            Spacer()

            accessory
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(isSelected ? design.accentColor : .clear)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
    }
}

#Preview {
    SettingsListRow(icon: "star.fill", title: "Example") {
        Image(systemName: "chevron.right")
            .foregroundColor(.secondary)
    }
}
