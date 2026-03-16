import SwiftUI

struct StreakStatsStack: View {
    enum LayoutStyle {
        case stacked
        case compactRow
    }

    let streak: Streak
    var layout: LayoutStyle = .stacked

    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        switch layout {
        case .stacked:
            stackedBody
        case .compactRow:
            compactRowBody
        }
    }

    private var stackedBody: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            StatCard(
                title: localization.localized("profile_current_streak"),
                value: "\(streak.currentStreak)",
                subtitle: localization.localized("profile_days"),
                icon: "flame.fill",
                color: design.accentColor
            )

            StatCard(
                title: localization.localized("profile_longest_streak"),
                value: "\(streak.longestStreak)",
                subtitle: localization.localized("profile_days"),
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )

            StatCard(
                title: localization.localized("profile_social_wins"),
                value: "\(streak.totalCollections)",
                subtitle: localization.localized("profile_collected"),
                icon: "checkmark.seal.fill",
                color: .purple
            )
        }
    }

    private var compactRowBody: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            compactStatCard(
                title: localization.localized("profile_current_streak"),
                value: "\(streak.currentStreak)",
                icon: "flame.fill",
                color: design.accentColor
            )

            compactStatCard(
                title: localization.localized("profile_longest_streak"),
                value: "\(streak.longestStreak)",
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )

            compactStatCard(
                title: localization.localized("profile_social_wins"),
                value: "\(streak.totalCollections)",
                icon: "checkmark.seal.fill",
                color: .purple
            )
        }
    }

    private func compactStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.16))
                .clipShape(Circle())

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(design.textColor)

            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.md)
        .streetBeastSurface()
    }
}

#Preview {
    VStack(spacing: 12) {
        StreakStatsStack(streak: Streak(currentStreak: 12, longestStreak: 21, totalCollections: 48))
        StreakStatsStack(
            streak: Streak(currentStreak: 12, longestStreak: 21, totalCollections: 48),
            layout: .compactRow
        )
    }
    .padding()
}
