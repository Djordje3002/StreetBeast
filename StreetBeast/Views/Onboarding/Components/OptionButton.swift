import SwiftUI

struct OptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject var design = DesignSystem.shared
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(isSelected ? .white : design.textColor)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(isSelected ? design.accentColor : design.paperColor)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isSelected ? design.accentColor : design.secondaryTextColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
