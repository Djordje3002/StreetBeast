import SwiftUI

struct QuestionLayout<Content: View>: View {
    let questionNumber: Int
    let question: String
    let subtitle: String
    @ViewBuilder let content: Content
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("\(localization.localized("question_prefix")) \(questionNumber)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(design.secondaryTextColor)
                
                Text(question)
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(design.textColor)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(design.secondaryTextColor)
            }
            .padding(.top, DesignSystem.Spacing.xl)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                design.backgroundColor

                LinearGradient(
                    colors: [
                        design.accentColor.opacity(0.08),
                        design.backgroundColor,
                        design.backgroundColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }
}
