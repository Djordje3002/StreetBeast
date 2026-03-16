import SwiftUI

struct SplashScreenView: View {
    @State private var bubbleScale: CGFloat = 1.4
    @State private var bubbleOpacity: Double = 0
    @State private var bubbleRotation: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var bgOpacity: Double = 0
    
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var localization = LocalizationManager.shared
    var onFinish: () -> Void = {}
    
    var body: some View {
        ZStack {
            // High-Contrast Vibrant Dark Background
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    Color(hex: "1A0B2E"), // Deep Midnight Purple
                    Color(hex: "0D051A"), // Near Black
                    .black
                ],
                center: .center,
                startRadius: 0,
                endRadius: 500
            )
            .opacity(bgOpacity)
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Glassmorphic Hero Asset
                ZStack {
                    // Soft aura behind the bubble
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "7928CA"), Color(hex: "FF0080")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 280, height: 280)
                        .blur(radius: 60)
                        .opacity(bubbleOpacity * 0.4)
                        .scaleEffect(bubbleScale)
                    
                    Image("ai-bubble") // The ai-bubble image set
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(bubbleRotation))
                        .scaleEffect(bubbleScale)
                        .opacity(bubbleOpacity)
                        .shadow(color: Color(hex: "7928CA").opacity(0.5), radius: 30, x: 0, y: 0)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text(localization.localized("app_name").uppercased())
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(8)
                        .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0)
                    
                    Text(localization.localized("splash_tagline").uppercased())
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(3)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            // Background Fade In
            withAnimation(.easeIn(duration: 1.0)) {
                bgOpacity = 1.0
            }
            
            // Hero Asset Animation
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7, blendDuration: 0).delay(0.3)) {
                bubbleScale = 1.0
                bubbleOpacity = 1.0
            }
            
            // Persistent slow rotation
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                bubbleRotation = 360
            }
            
            // Text Entrance
            withAnimation(.easeOut(duration: 1.0).delay(0.8)) {
                textOpacity = 1.0
                textOffset = 0
            }
            
            // Exit Animation (Scale up bubble)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeIn(duration: 0.5)) {
                    bubbleScale = 15.0 // Get so big it covers the screen
                    textOpacity = 0.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onFinish()
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
