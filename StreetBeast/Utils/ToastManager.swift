import SwiftUI
import Combine

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var toasts: [Toast] = []
    
    private init() {}
    
    func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
        let toast = Toast(message: message, type: type, duration: duration)
        
        DispatchQueue.main.async {
            self.toasts.append(toast)
            
            // Auto dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.dismiss(toast)
            }
        }
    }
    
    func dismiss(_ toast: Toast) {
        withAnimation {
            toasts.removeAll { $0.id == toast.id }
        }
    }
    
    func dismissAll() {
        withAnimation {
            toasts.removeAll()
        }
    }
}

extension View {
    func toast() -> some View {
        modifier(ToastModifier())
    }
}
