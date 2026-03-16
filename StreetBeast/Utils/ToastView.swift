import SwiftUI

struct ToastView: View {
    let toast: Toast
    @ObservedObject var design = DesignSystem.shared
    @State private var isVisible = false
    
    var icon: String {
        switch toast.type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch toast.type {
        case .success: return .green
        case .error: return .red
        case .info: return design.accentColor
        case .warning: return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(toast.message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(design.textColor)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            design.paperColor
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -100)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    ToastView(
        toast: Toast(
            message: "Sample success toast",
            type: .success,
            duration: 3.0
        )
    )
}
