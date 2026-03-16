import SwiftUI

struct ProfileView: View {
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject var localization = LocalizationManager.shared
    let userService = UserService.shared
    @State private var streak: Streak = Streak()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            StreetBeastBackground()
            
            VStack(spacing: 0) {
                // Header with custom title if needed
                ScreenHeader(
                    title: localization.localized("profile_title"),
                    leading: {
                        HeaderBackButton(
                            accessibilityLabel: localization.localized("a11y_back"),
                            accessibilityHint: localization.localized("a11y_back_hint"),
                            action: { dismiss() }
                        )
                        .padding(.trailing, 8)
                    },
                    trailing: { EmptyView() },
                    bottom: { EmptyView() }
                )
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Profile Header
                        VStack(spacing: DesignSystem.Spacing.md) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [design.accentColor, design.accentColor.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image("default-avatar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                Text((authManager.currentUser?.preferredDisplayName) ?? localization.localized("user_unknown"))
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .neonShadow(color: design.accentColor, radius: 5)
                                
                                Text(authManager.currentUser?.email ?? "")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(.top, DesignSystem.Spacing.xl)
                        
                        // Stats Cards
                        StreakStatsStack(streak: streak)
                        .padding(.horizontal, DesignSystem.Spacing.lg)

                        // Profile Stats
                        profileStatsSection
                        
                        // Leaderboard Card
                        NavigationLink(destination: LeaderboardView()) {
                            NavigationSurfaceCard(
                                spacing: DesignSystem.Spacing.lg,
                                horizontalPadding: DesignSystem.Spacing.lg,
                                verticalPadding: DesignSystem.Spacing.md,
                                chevronColor: .white.opacity(0.4),
                                leading: {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.orange.opacity(0.12), .orange.opacity(0.06)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 60, height: 60)
                                        
                                        SymbolStickerView(
                                            symbol: "trophy.fill",
                                            size: 32,
                                            colors: [.orange, .yellow],
                                            backgroundColor: design.paperColor,
                                            isSimple: true
                                        )
                                    }
                                },
                                content: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(localization.localized("profile_leaderboard_title"))
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text(localization.localized("profile_leaderboard_subtitle"))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            )
                            .streetBeastGlow(.orange.opacity(0.2), radius: 10)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                        
                        // Milestone Icons Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text(localization.localized("profile_milestone_icons"))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DesignSystem.Spacing.lg) {
                                    AchievementMilestoneView(
                                        symbolName: "person.2.wave.2.fill",
                                        symbolColors: [design.accentColor, design.candleColor],
                                        title: localization.localized("profile_milestone_social_starter"),
                                        milestone: 7,
                                        currentStreak: streak.currentStreak
                                    )
                                    
                                    AchievementMilestoneView(
                                        symbolName: "bolt.fill",
                                        symbolColors: [.orange, .yellow],
                                        title: localization.localized("profile_milestone_momentum"),
                                        milestone: 30,
                                        currentStreak: streak.currentStreak
                                    )
                                    
                                    AchievementMilestoneView(
                                        symbolName: "crown.fill",
                                        symbolColors: [.purple, .pink],
                                        title: localization.localized("profile_milestone_unstoppable"),
                                        milestone: 100,
                                        currentStreak: streak.currentStreak
                                    )
                                }
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                .padding(.vertical, 10)
                            }
                        }
                        .padding(.top, DesignSystem.Spacing.sm)

                        // Skill Tree
                        skillTreeSection
                        
                        // Member Since
                        if let createdAt = authManager.currentUser?.createdAt {
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                Text(localization.localized("profile_member_since"))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(design.secondaryTextColor)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                
                                Text(createdAt, style: .date)
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(design.textColor)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(design.paperColor)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadStats()
        }
        .dynamicTypeSize(.medium ... .accessibility3)
    }
    
    private func loadStats() async {
        do {
            let response = try await userService.getStreak()
            let lastCollectionDate = response.lastCollectionDate.flatMap { ISO8601DateFormatter().date(from: $0) }
            await MainActor.run {
                streak = Streak(
                    currentStreak: response.currentStreak,
                    longestStreak: response.longestStreak,
                    lastCollectionDate: lastCollectionDate,
                    totalCollections: response.totalCollections
                )
            }
        } catch { }
    }
}

// MARK: - Profile Stats + Skill Tree
private extension ProfileView {
    var totalXP: Int {
        XPLeveling.totalXP(forChallenges: streak.totalCollections)
    }

    var level: Int {
        XPLeveling.levelInfo(totalXP: totalXP).level
    }

    var strengthScore: Int {
        (streak.totalCollections * 10) + (streak.longestStreak * 15) + (streak.currentStreak * 20)
    }

    var profileStatsSection: some View {
        SectionBlock(title: localization.localized("profile_stats_title")) {
            SettingsCardGroup {
                SettingsListRow(icon: "star.fill", title: localization.localized("profile_level_label")) {
                    Text("\(level)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(design.textColor)
                }
                SettingsRowDivider()

                SettingsListRow(icon: "bolt.fill", title: localization.localized("profile_total_xp_label")) {
                    Text("\(totalXP)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(design.textColor)
                }
                SettingsRowDivider()

                SettingsListRow(icon: "figure.strengthtraining.traditional", title: localization.localized("profile_strength_score_label")) {
                    Text("\(strengthScore)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(design.textColor)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    var skillTreeSection: some View {
        SectionBlock(title: localization.localized("profile_skill_tree_title")) {
            NavigationSurfaceCard(
                spacing: DesignSystem.Spacing.md,
                horizontalPadding: DesignSystem.Spacing.lg,
                verticalPadding: DesignSystem.Spacing.lg,
                showChevron: false,
                style: .clean,
                leading: {
                    Circle()
                        .fill(design.accentColor.opacity(0.16))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "tree.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(design.accentColor)
                        )
                },
                content: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.localized("profile_skill_tree_path"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(design.textColor)

                        Text(localization.localized("profile_skill_tree_subtitle"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(design.secondaryTextColor)
                    }
                }
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

struct AchievementMilestoneView: View {
    let symbolName: String
    let symbolColors: [Color]
    let title: String
    let milestone: Int
    let currentStreak: Int
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var localization = LocalizationManager.shared
    
    var isUnlocked: Bool {
        currentStreak >= milestone
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(design.paperColor)
                    .frame(width: 82, height: 82)
                    .overlay(
                        Circle()
                            .strokeBorder(design.accentColor.opacity(isUnlocked ? 0.35 : 0.12), lineWidth: 1.4)
                    )

                if isUnlocked {
                    Image(systemName: symbolName)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: symbolColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: symbolColors.first?.opacity(0.25) ?? .clear, radius: 6, x: 0, y: 2)
                } else {
                    ZStack {
                        Image(systemName: symbolName)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(design.secondaryTextColor.opacity(0.45))
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(design.secondaryTextColor)
                            .padding(6)
                            .background(design.paperColor.opacity(0.92))
                            .clipShape(Circle())
                            .offset(x: 24, y: -24)
                    }
                }
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)
                
                Text("\(milestone) \(localization.localized("profile_day_streak"))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(design.secondaryTextColor)
            }
        }
    }
}


#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(DesignSystem.shared)
            .environmentObject(AuthManager.shared)
    }
}
