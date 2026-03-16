import SwiftUI
import Combine

class DesignSystem: ObservableObject {
    static let shared = DesignSystem()
    
    // MARK: - Colors
    
    private func themeColor(_ token: ThemeColorToken) -> Color {
        ThemeColorAssets.color(token)
    }
    
    var backgroundColor: Color { themeColor(.background) }
    var paperColor: Color { themeColor(.paper) }
    var textColor: Color { themeColor(.text) }
    var secondaryTextColor: Color { themeColor(.secondaryText) }
    var accentColor: Color { themeColor(.accent) }
    var candleColor: Color { themeColor(.candle) }
    var flameColor: Color { themeColor(.flame) }
    
    // MARK: - Typography
    
    struct Typography {
        // Content text - Rounded for modern feel
        static let bodyText = Font.system(.body, design: .rounded)
        static let bodyTextLarge = Font.system(.title2, design: .rounded)
        static let bodyTextSmall = Font.system(.callout, design: .rounded)
        
        // Reference - Italic rounded
        static let reference = Font.system(.subheadline, design: .rounded).italic()
        static let referenceSmall = Font.system(.caption, design: .rounded).italic()
        
        // UI Elements - Sans-serif
        static let title = Font.system(size: 34, weight: .black, design: .rounded)
        static let headline = Font.system(.headline, design: .default).weight(.semibold)
        static let body = Font.system(.body, design: .default)
        static let caption = Font.system(.caption, design: .default)
        static let button = Font.system(.headline, design: .default).weight(.semibold)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
    }
    
    // MARK: - Shadows
    
    struct Shadows {
        static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let large = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

enum ThemeColorToken: String {
    case background
    case paper
    case text
    case secondaryText
    case accent
    case candle
    case flame
}

struct ThemeColorAssets {
    private static let themePrefix = "ThemeModern"

    static func color(_ token: ThemeColorToken) -> Color {
        Color(themePrefix + token.assetSuffix)
    }
}

private extension ThemeColorToken {
    var assetSuffix: String {
        switch self {
        case .background: return "Background"
        case .paper: return "Paper"
        case .text: return "Text"
        case .secondaryText: return "SecondaryText"
        case .accent: return "Accent"
        case .candle: return "Candle"
        case .flame: return "Flame"
        }
    }
}

// MARK: - View Modifiers

struct StreetBeastSurface: ViewModifier {
    @ObservedObject private var design = DesignSystem.shared

    func body(content: Content) -> some View {
        content
            .background(design.paperColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(design.accentColor.opacity(0.1), lineWidth: 1)
            )
    }
}

struct ThemeStyleModifier: ViewModifier {
    @ObservedObject private var design = DesignSystem.shared

    func body(content: Content) -> some View {
        content
            .foregroundStyle(design.textColor)
    }
}

// MARK: - App Primitives

struct StreetBeastBackground: View {
    @ObservedObject var design = DesignSystem.shared
    
    var body: some View {
        ZStack {
            design.backgroundColor
            
            // Subtle Hexagonal Grid
            GeometryReader { geo in
                Path { path in
                    let stepX: CGFloat = 40
                    let stepY: CGFloat = 35
                    for y in stride(from: 0, to: geo.size.height + stepY, by: stepY) {
                        for x in stride(from: 0, to: geo.size.width + stepX, by: stepX) {
                            let xOffset = (Int(y/stepY) % 2 == 0) ? 0 : stepX / 2
                            drawHexagon(in: &path, center: CGPoint(x: x + xOffset, y: y), radius: 20)
                        }
                    }
                }
                .stroke(design.accentColor.opacity(0.08), lineWidth: 1)
            }
            
            // Ambient Flows
            RadialGradient(
                colors: [design.accentColor.opacity(0.2), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 500
            )
            
            RadialGradient(
                colors: [design.accentColor.opacity(0.12), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 600
            )
            
            // Depth Mist
            LinearGradient(
                colors: [.clear, design.backgroundColor.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
    
    private func drawHexagon(in path: inout Path, center: CGPoint, radius: CGFloat) {
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3
            let pt = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
    }
}

// MARK: - View Modifiers Extension

extension View {
    func streetBeastStyle() -> some View {
        modifier(ThemeStyleModifier())
    }

    func streetBeastSurface() -> some View {
        modifier(StreetBeastSurface())
    }
    
    func neonShadow(color: Color, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius / 2)
    }
}

// MARK: - Components

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let x = rect.minX
        let y = rect.minY
        
        path.move(to: CGPoint(x: x + width * 0.5, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y + height * 0.25))
        path.addLine(to: CGPoint(x: x + width, y: y + height * 0.75))
        path.addLine(to: CGPoint(x: x + width * 0.5, y: y + height))
        path.addLine(to: CGPoint(x: x, y: y + height * 0.75))
        path.addLine(to: CGPoint(x: x, y: y + height * 0.25))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Sheep Sticker Component
struct SheepStickerView: View {
    let imageName: String
    let size: CGFloat
    var borderSize: CGFloat = 3
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .padding(borderSize)
            .background(Color.white)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(Color.white, lineWidth: borderSize)
            )
            .shadow(color: .black.opacity(0.12), radius: size * 0.1, x: 0, y: size * 0.05)
    }
}
