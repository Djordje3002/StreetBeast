import SwiftUI

enum NavigationSurfaceStyle {
    case streetBeast
    case clean
}

struct NavigationSurfaceCard<Leading: View, Content: View>: View {
    var spacing: CGFloat = DesignSystem.Spacing.md
    var horizontalPadding: CGFloat = DesignSystem.Spacing.lg
    var verticalPadding: CGFloat = DesignSystem.Spacing.md
    var chevronColor: Color? = nil
    var showChevron: Bool = true
    var style: NavigationSurfaceStyle = .streetBeast

    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let content: () -> Content

    @ObservedObject private var design = DesignSystem.shared

    var body: some View {
        Group {
            if case .clean = style {
                cardContent
                    .settingsCardSurface()
            } else {
                cardContent
                    .streetBeastSurface()
            }
        }
    }

    private var cardContent: some View {
        HStack(spacing: spacing) {
            leading()
            content()
            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(chevronColor ?? design.secondaryTextColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, verticalPadding)
    }
}

#Preview {
    NavigationSurfaceCard(
        leading: {
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 48, height: 48)
        },
        content: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                Text("Subtitle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    )
}
