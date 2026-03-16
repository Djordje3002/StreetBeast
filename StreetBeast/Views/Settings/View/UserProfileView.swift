import SwiftUI

struct UserProfileView: View {
    let entry: LeaderboardEntry
    let rank: Int?
    
    @StateObject private var profileService = PublicProfileService()
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            StreetBeastBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    headerProfileInfo
                    
                    if profileService.isLoading {
                        ProgressView()
                            .tint(design.accentColor)
                            .padding(.top, 40)
                    } else if profileService.error != nil {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                            Text(localization.localized("profile_load_error"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(design.secondaryTextColor)
                        }
                        .padding(.top, 40)
                    } else if let profile = profileService.profile {
                        statsGrid(profile: profile)
                        
                        if let joinDate = profile.joinDate {
                            joinDateBanner(date: joinDate)
                        }
                    } else {
                        // Fallback state while initializing
                        statsGrid(profile: PublicProfileData(
                            id: entry.id,
                            name: entry.name,
                            socialWins: entry.socialWins,
                            initials: entry.initials,
                            currentStreak: 0,
                            longestStreak: 0,
                            joinDate: nil
                        ))
                    }
                }
                .padding(.top, 120)
                .padding(.bottom, 60)
            }
            .refreshable {
                await profileService.fetchProfile(
                    for: entry.id,
                    entryName: entry.name,
                    entryWins: entry.socialWins,
                    entryInitials: entry.initials
                )
            }
            
            navBar
        }
        .navigationBarHidden(true)
        .task {
            await profileService.fetchProfile(
                for: entry.id,
                entryName: entry.name,
                entryWins: entry.socialWins,
                entryInitials: entry.initials
            )
        }
    }
    
    private var navBar: some View {
        HStack {
            HeaderBackButton(
                accessibilityLabel: localization.localized("a11y_back"),
                accessibilityHint: localization.localized("a11y_back_hint"),
                action: { dismiss() }
            )
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, 60) // Safe area top inset approximation
    }
    
    private var headerProfileInfo: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(design.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image("default-avatar") // Assuming "default-avatar" exists from standard UI
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                if let rank = rank {
                    let badgeColor: Color = {
                        switch rank {
                        case 1: return Color(red: 1.0, green: 0.7, blue: 0.0)
                        case 2: return Color(red: 0.75, green: 0.75, blue: 0.85)
                        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
                        default: return design.secondaryTextColor
                        }
                    }()
                    
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(badgeColor)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 40, y: 40)
                    
                    if rank == 1 {
                        SymbolStickerView(symbol: "crown.fill", size: 36, colors: [.orange, .yellow])
                            .offset(y: -65)
                    }
                }
            }
            
            VStack(spacing: 4) {
                Text(entry.name)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(design.textColor)
                
                if entry.isCurrentUser {
                    Text(localization.localized("leaderboard_you_label"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(design.accentColor)
                }
            }
        }
    }
    
    private func statsGrid(profile: PublicProfileData) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            statCard(
                title: localization.localized("leaderboard_category_max"),
                value: "\(profile.socialWins)",
                icon: "figure.strengthtraining.traditional",
                color: design.flameColor
            )
            
            statCard(
                title: localization.localized("profile_xp_label"),
                value: "\(profile.socialWins * 40)",
                icon: "bolt.fill",
                color: design.accentColor
            )
            
            statCard(
                title: localization.localized("profile_current_streak_label"),
                value: "\(profile.currentStreak)",
                icon: "flame.fill",
                color: Color.orange
            )
            
            statCard(
                title: localization.localized("profile_longest_streak_label"),
                value: "\(profile.longestStreak)",
                icon: "star.fill",
                color: Color.yellow
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(design.secondaryTextColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .streetBeastSurface()
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func joinDateBanner(date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: localization.currentLanguage.rawValue)
        
        return HStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(design.secondaryTextColor)
            
            Text(String(format: localization.localized("profile_joined_format"), formatter.string(from: date)))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
        .padding(.top, 8)
    }
}
