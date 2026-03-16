import SwiftUI

struct SectionCaption: View {
    let title: String
    var subtitle: String? = nil

    @ObservedObject private var design = DesignSystem.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(design.secondaryTextColor)
                .tracking(1)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(design.secondaryTextColor.opacity(0.8))
            }
        }
    }
}

#Preview {
    SectionCaption(title: "Section", subtitle: "Short helper subtitle")
}
