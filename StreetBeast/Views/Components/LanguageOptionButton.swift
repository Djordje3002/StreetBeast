import SwiftUI

struct LanguageOptionButton: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject var design = DesignSystem.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Text(flagForLanguage(language))
                    .font(.system(size: 24))
                    .frame(width: 32, height: 32)
                    .background(isSelected ? design.accentColor : design.accentColor.opacity(0.1))
                    .clipShape(Circle())
                
                Text(language.displayName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : design.textColor)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .settingsCardSurface(isSelected: isSelected)
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func flagForLanguage(_ language: Language) -> String {
        switch language {
        case .english: return "🇺🇸"
        case .serbian: return "🇷🇸"
        }
    }
}


#Preview {
    LanguageOptionButton(language: .english, isSelected: true, action: {})
}
