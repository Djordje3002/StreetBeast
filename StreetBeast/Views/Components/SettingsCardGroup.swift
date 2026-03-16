import SwiftUI

struct SettingsCardGroup<Content: View>: View {
    var spacing: CGFloat = DesignSystem.Spacing.xs
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: spacing) {
            content()
        }
        .settingsCardSurface()
    }
}

struct SettingsRowDivider: View {
    @ObservedObject private var design = DesignSystem.shared

    var body: some View {
        Divider()
            .background(design.accentColor.opacity(0.1))
            .padding(.horizontal, DesignSystem.Spacing.sm)
    }
}

struct SettingsCardSurfaceModifier: ViewModifier {
    var isSelected: Bool = false
    @ObservedObject private var design = DesignSystem.shared

    func body(content: Content) -> some View {
        content
            .background(isSelected ? design.accentColor : design.paperColor)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.05), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .strokeBorder(design.accentColor.opacity(isSelected ? 0 : 0.1), lineWidth: 1)
            )
    }
}

extension View {
    func settingsCardSurface(isSelected: Bool = false) -> some View {
        modifier(SettingsCardSurfaceModifier(isSelected: isSelected))
    }
}

#Preview {
    SettingsCardGroup {
        SettingsListRow(icon: "star.fill", title: "Row 1") { EmptyView() }
        SettingsRowDivider()
        SettingsListRow(icon: "heart.fill", title: "Row 2") { EmptyView() }
    }
}
