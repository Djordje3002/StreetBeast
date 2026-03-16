//
//  SymbolStickerView.swift
//  StreetBeast
//
//  Created by Djordje on 12. 2. 2026..
//

import SwiftUI

struct SymbolStickerView: View {
    let symbol: String
    let size: CGFloat
    let colors: [Color]
    var borderSize: CGFloat = 3
    var backgroundColor: Color = .white
    var borderColor: Color = .white
    var symbolOutlineColor: Color = .black.opacity(0.25)
    var symbolOutlineScale: CGFloat = 1.08
    var isSimple: Bool = false
    
    var body: some View {
        ZStack {
            if isSimple {
                Circle()
                    .fill(backgroundColor)
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.6, height: size * 0.6)
                    .foregroundStyle(colors.first ?? Color.primary)
            } else {
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.6, height: size * 0.6)
                    .foregroundColor(symbolOutlineColor)
                    .scaleEffect(symbolOutlineScale)
                
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.6, height: size * 0.6)
                    .foregroundStyle(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .frame(width: size, height: size)
        .background(isSimple ? Color.clear : backgroundColor)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(borderColor, lineWidth: isSimple ? 0 : borderSize)
        )
        .shadow(color: .black.opacity(isSimple ? 0 : 0.12), radius: size * 0.08, x: 0, y: size * 0.04)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Rich style
        SymbolStickerView(
            symbol: "trophy.fill",
            size: 100,
            colors: [.orange, .yellow]
        )
        // Simple style
        SymbolStickerView(
            symbol: "sun.max.fill",
            size: 80,
            colors: [.yellow],
            backgroundColor: .white,
            isSimple: true
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
