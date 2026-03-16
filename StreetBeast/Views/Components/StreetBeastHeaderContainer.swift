import SwiftUI

struct StreetBeastHeaderContainer<Content: View>: View {
    var topPadding: CGFloat = 16
    var bottomPadding: CGFloat = 20
    var contentSpacing: CGFloat = 0
    @ViewBuilder let content: () -> Content

    @ObservedObject private var design = DesignSystem.shared

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: contentSpacing) {
                content()
            }
            .padding(.horizontal, 24)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .background {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                design.backgroundColor,
                                design.paperColor.opacity(0.92),
                                design.backgroundColor.opacity(0.88)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [design.accentColor.opacity(0.5), .clear, design.accentColor.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .neonShadow(color: design.accentColor, radius: 4)
            }
        }
    }
}

#Preview {
    StreetBeastHeaderContainer {
        Text("Header")
            .font(DesignSystem.Typography.title)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
