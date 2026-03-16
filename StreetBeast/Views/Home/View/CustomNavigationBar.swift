//
//  CustomNavigationBar.swift
//  StreetBeast
//
//  Created by Djordje on 13. 1. 2026..
//


import SwiftUI

struct CustomNavigationBar: View {
    let title: String
    var streak: Int = 0
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var localization = LocalizationManager.shared
    @ObservedObject var authManager = AuthManager.shared
    
    var body: some View {
        StreetBeastHeaderContainer(contentSpacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(design.textColor)
                            .neonShadow(color: design.accentColor, radius: 8)
                        
                        SymbolStickerView(
                            symbol: "sun.max.fill",
                            size: 24,
                            colors: [.yellow],
                            backgroundColor: .clear,
                            isSimple: true
                        )
                    }
                    
                    xpProgressRow
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if streak > 0 {
                        HStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 14))
                            Text("\(streak)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(design.textColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(design.accentColor.opacity(0.2))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(design.accentColor.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    NavigationLink(destination: ProfileView()) {
                        ZStack {
                            Circle()
                                .fill(design.accentColor.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image("default-avatar")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(design.textColor.opacity(0.35), lineWidth: 1.5)
                                )
                        }
                    }
                }
            }
        }
    }

    private var xpProgressRow: some View {
        let totalChallenges = max(
            authManager.currentUser?.totalChallengesCompleted ?? 0,
            UserService.shared.getTotalChallengesCompleted()
        )
        let totalXP = XPLeveling.totalXP(forChallenges: totalChallenges)
        let levelInfo = XPLeveling.levelInfo(totalXP: totalXP)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("\(localization.localized("home_level_short")) \(levelInfo.level)/\(XPLeveling.maxLevel)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))

                Text(String(format: localization.localized("sim_xp_amount_format"), totalXP))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(design.secondaryTextColor)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(design.paperColor.opacity(0.6))

                    Capsule()
                        .fill(design.accentColor)
                        .frame(width: geo.size.width * levelInfo.progress)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: 200)
    }
    
}

#Preview {
    CustomNavigationBar(title: LocalizationManager.shared.localized("app_name"))
        .background(DesignSystem.shared.backgroundColor)
}
