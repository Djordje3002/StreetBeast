import SwiftUI

struct SectionBlock<Content: View>: View {
    let title: String
    var spacing: CGFloat = DesignSystem.Spacing.md
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            SectionCaption(title: title)
            content()
        }
    }
}

#Preview {
    SectionBlock(title: "Section") {
        Text("Body")
    }
}
