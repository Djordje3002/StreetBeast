import SwiftUI

struct HeaderBackButton: View {
    let accessibilityLabel: String
    let accessibilityHint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}

struct ScreenHeader<Leading: View, Trailing: View, Bottom: View>: View {
    let title: String
    var topPadding: CGFloat = 16
    var bottomPadding: CGFloat = 20
    var contentSpacing: CGFloat = 12

    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing
    @ViewBuilder let bottom: () -> Bottom

    @ObservedObject private var design = DesignSystem.shared

    var body: some View {
        StreetBeastHeaderContainer(
            topPadding: topPadding,
            bottomPadding: bottomPadding,
            contentSpacing: contentSpacing
        ) {
            HStack(spacing: 8) {
                leading()

                Text(title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .neonShadow(color: design.accentColor, radius: 10)

                Spacer()

                trailing()
            }

            bottom()
        }
    }
}

#Preview {
    ScreenHeader(
        title: "Header",
        leading: { HeaderBackButton(accessibilityLabel: "Back", accessibilityHint: "Go back", action: {}) },
        trailing: { EmptyView() },
        bottom: { EmptyView() }
    )
}
