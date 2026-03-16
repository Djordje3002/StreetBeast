import SwiftUI

struct PasswordStrengthIndicator: View {
    let password: String
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var localization = LocalizationManager.shared
    
    var strength: (color: Color, textKey: String, value: Double) {
        let length = password.count
        var score = 0.0
        
        if length >= 6 { score += 0.25 }
        if length >= 8 { score += 0.25 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 0.25 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil || password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 0.25 }
        
        switch score {
        case 0..<0.5:
            return (.red, "auth_password_strength_weak", score)
        case 0.5..<0.75:
            return (.orange, "auth_password_strength_fair", score)
        case 0.75..<1.0:
            return (.green, "auth_password_strength_good", score)
        default:
            return (.green, "auth_password_strength_strong", 1.0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(design.secondaryTextColor.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(strength.color)
                        .frame(width: geometry.size.width * strength.value, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            
            Text(
                String(
                    format: localization.localized("auth_password_strength_format"),
                    localization.localized(strength.textKey)
                )
            )
                .font(DesignSystem.Typography.caption)
                .foregroundColor(strength.color)
        }
        .accessibilityElement(children: .combine)
    }
}
