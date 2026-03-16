import SwiftUI

struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared
    @ObservedObject var design = DesignSystem.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(toastManager.toasts) { toast in
                    ToastView(toast: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, DesignSystem.Spacing.md)
            .zIndex(1000)
        }
    }
}
