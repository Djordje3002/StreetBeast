import SwiftUI

struct ModernTextFieldStyle: TextFieldStyle {
    @ObservedObject var design = DesignSystem.shared
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(design.paperColor)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(design.secondaryTextColor.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(design.textColor)
    }
}
