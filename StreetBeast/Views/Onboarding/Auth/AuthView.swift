import SwiftUI

struct AuthView: View {
    @State private var showSignUp = false
    @ObservedObject var authManager = AuthManager.shared
    
    var body: some View {
        ZStack {
            if showSignUp {
                SignUpView(onLogin: {
                    withAnimation {
                        showSignUp = false
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                LoginView(onSignUp: {
                    withAnimation {
                        showSignUp = true
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .dynamicTypeSize(.medium ... .accessibility3)
    }
}
