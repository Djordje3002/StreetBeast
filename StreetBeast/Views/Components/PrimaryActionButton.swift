import SwiftUI

struct PrimaryActionButton<Label: View>: View {
    @ObservedObject private var design = DesignSystem.shared
    let action: () -> Void
    var isEnabled: Bool = true
    var verticalPadding: CGFloat = DesignSystem.Spacing.md
    var horizontalPadding: CGFloat = DesignSystem.Spacing.md
    var backgroundColor: Color? = nil
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.medium
    var textColor: Color = .white
    let label: Label
    
    init(
        title: String,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        verticalPadding: CGFloat = DesignSystem.Spacing.md,
        horizontalPadding: CGFloat = DesignSystem.Spacing.md,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.medium,
        textColor: Color = .white
    ) where Label == Text {
        self.action = action
        self.isEnabled = isEnabled
        self.verticalPadding = verticalPadding
        self.horizontalPadding = horizontalPadding
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.textColor = textColor
        self.label = Text(title)
    }
    
    init(
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        verticalPadding: CGFloat = DesignSystem.Spacing.md,
        horizontalPadding: CGFloat = DesignSystem.Spacing.md,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.medium,
        textColor: Color = .white,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.isEnabled = isEnabled
        self.verticalPadding = verticalPadding
        self.horizontalPadding = horizontalPadding
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.textColor = textColor
        self.label = label()
    }
    
    var body: some View {
        Button(action: action) {
            label
                .font(DesignSystem.Typography.button)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, verticalPadding)
                .padding(.horizontal, horizontalPadding)
                .background(backgroundColor ?? design.accentColor)
                .cornerRadius(cornerRadius)
                .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Using the title-based initializer
        PrimaryActionButton(title: "Continue") {
            // no-op
        }
        
        // Using the label-based initializer
        PrimaryActionButton(action: {}) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Custom Label")
            }
        }
    }
    .padding()
    .background(DesignSystem.shared.backgroundColor)
}
