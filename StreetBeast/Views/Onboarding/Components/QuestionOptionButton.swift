import SwiftUI

struct QuestionOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject var design = DesignSystem.shared
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundColor(isSelected ? .white : design.textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(isSelected ? design.accentColor : design.paperColor)
                .cornerRadius(DesignSystem.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .stroke(isSelected ? design.accentColor : design.secondaryTextColor.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
