import SwiftUI

extension AnyTransition {
    static var streetBeastPop: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }

    static var streetBeastSlideUp: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}

extension View {
    func streetBeastGlow(_ color: Color, radius: CGFloat = 10) -> some View {
        neonShadow(color: color, radius: radius)
    }
}
