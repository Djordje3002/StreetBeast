import SwiftUI

struct LeaderboardView: View {
    @StateObject private var leaderboardService = LeaderboardService.shared
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: LeaderboardCategory = .maxStrength
    @State private var categoryPulseScale: [LeaderboardCategory: CGFloat] = [:]
    @Namespace private var categorySelectionAnimation
    private let topInset: CGFloat = 120
    var usesGlobalHeader: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            StreetBeastBackground()
            
            VStack(spacing: 0) {
                if usesGlobalHeader {
                    categorySelector
                } else {
                    header
                }
                
                if leaderboardService.isLoading && leaderboardService.topEntries.isEmpty {
                    loadingState
                } else if leaderboardService.error != nil && leaderboardService.topEntries.isEmpty {
                    errorState
                } else if leaderboardService.topEntries.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DesignSystem.Spacing.xl) {
                            if leaderboardService.error != nil {
                                staleDataBanner
                            }

                            if leaderboardService.topEntries.count >= 3 {
                                podiumSection
                            }
                            
                            remainingList
                        }
                        .padding(.top, DesignSystem.Spacing.md)
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        await leaderboardService.fetchLeaderboard()
                    }
                }
            }
            .padding(.top, usesGlobalHeader ? topInset : 0)
            .padding(.bottom, 50)
            
            currentUserStickyBar
        }
        .navigationBarHidden(true)
        .task {
            await leaderboardService.fetchLeaderboard()
        }
    }
}

// MARK: - Header
private extension LeaderboardView {
    var header: some View {
        ScreenHeader(
            title: localization.localized("leaderboard_screen_title"),
            leading: {
                HeaderBackButton(
                    accessibilityLabel: localization.localized("a11y_back"),
                    accessibilityHint: localization.localized("a11y_back_hint"),
                    action: { dismiss() }
                )
                .padding(.trailing, 8)
            },
            trailing: { EmptyView() },
            bottom: { categorySelector }
        )
    }
}

// MARK: - Categories
private extension LeaderboardView {
    enum LeaderboardCategory: Int, CaseIterable, Identifiable {
        case maxStrength
        case xp
        case weeklyDedication

        var id: Int { rawValue }

        var titleKey: String {
            switch self {
            case .maxStrength: return "leaderboard_category_max"
            case .xp: return "leaderboard_category_xp"
            case .weeklyDedication: return "leaderboard_category_weekly"
            }
        }

        var icon: String {
            switch self {
            case .maxStrength: return "figure.strengthtraining.traditional"
            case .xp: return "bolt.fill"
            case .weeklyDedication: return "calendar"
            }
        }

        var labelKey: String {
            switch self {
            case .maxStrength: return "leaderboard_reps_label"
            case .xp: return "leaderboard_xp_label"
            case .weeklyDedication: return "leaderboard_workouts_label"
            }
        }

        var formatKey: String {
            switch self {
            case .maxStrength: return "leaderboard_reps_format"
            case .xp: return "leaderboard_xp_format"
            case .weeklyDedication: return "leaderboard_workouts_format"
            }
        }

        func value(for entry: LeaderboardEntry) -> Int {
            switch self {
            case .maxStrength:
                return entry.socialWins
            case .xp:
                return entry.socialWins * 40
            case .weeklyDedication:
                return max(1, min(12, entry.socialWins / 3))
            }
        }
    }

    var categorySelector: some View {
        HStack(spacing: 10) {
            ForEach(LeaderboardCategory.allCases) { category in
                Button {
                    select(category: category)
                } label: {
                    categoryTabItem(for: category)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(design.paperColor.opacity(0.95))
                .shadow(color: .black.opacity(0.2), radius: 18, x: 0, y: 8)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(design.accentColor.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, 8)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: selectedCategory)
    }

    func categoryTabItem(for category: LeaderboardCategory) -> some View {
        let isSelected = selectedCategory == category
        let pulseScale = categoryPulseScale[category] ?? 1.0

        return HStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.system(size: isSelected ? 16 : 15, weight: isSelected ? .semibold : .medium))

            if isSelected {
                Text(localization.localized(category.titleKey))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .foregroundStyle(isSelected ? Color.white : design.secondaryTextColor)
        .frame(height: 44)
        .frame(minWidth: isSelected ? 120 : 48)
        .padding(.horizontal, isSelected ? 12 : 0)
        .background {
            if isSelected {
                Capsule(style: .continuous)
                    .fill(selectedCategoryGradient)
                    .matchedGeometryEffect(id: "leaderboardCategoryBackground", in: categorySelectionAnimation)
            } else {
                Capsule(style: .continuous)
                    .fill(Color.clear)
            }
        }
        .overlay {
            if isSelected {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }
        }
        .scaleEffect((isSelected ? 1.0 : 0.94) * pulseScale)
        .contentShape(Capsule(style: .continuous))
    }

    var selectedCategoryGradient: LinearGradient {
        LinearGradient(
            colors: [design.accentColor, design.flameColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func select(category: LeaderboardCategory) {
        triggerCategoryPulse(for: category)

        guard category != selectedCategory else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            return
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
            selectedCategory = category
        }
    }

    func triggerCategoryPulse(for category: LeaderboardCategory) {
        categoryPulseScale[category] = 1.0

        withAnimation(.spring(response: 0.18, dampingFraction: 0.58)) {
            categoryPulseScale[category] = 1.1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
                categoryPulseScale[category] = 1.0
            }
        }
    }

    func scoreValue(for entry: LeaderboardEntry) -> Int {
        selectedCategory.value(for: entry)
    }

    func scoreLabel() -> String {
        localization.localized(selectedCategory.labelKey)
    }

    func formattedScore(for entry: LeaderboardEntry) -> String {
        String(format: localization.localized(selectedCategory.formatKey), scoreValue(for: entry))
    }
}

// MARK: - Podium Section
private extension LeaderboardView {
    var podiumSection: some View {
        let entries = leaderboardService.topEntries
        return HStack(alignment: .bottom, spacing: 10) {
            // 2nd Place
            NavigationLink(destination: UserProfileView(entry: entries[1], rank: 2)) {
                podiumColumn(entry: entries[1], rank: 2, height: 140, color: Color(red: 0.75, green: 0.75, blue: 0.85)) // Silver
            }
            .buttonStyle(.plain)
            
            // 1st Place
            NavigationLink(destination: UserProfileView(entry: entries[0], rank: 1)) {
                podiumColumn(entry: entries[0], rank: 1, height: 180, color: Color(red: 1.0, green: 0.7, blue: 0.0)) // Gold
            }
            .buttonStyle(.plain)
            .zIndex(1)
            
            // 3rd Place
            NavigationLink(destination: UserProfileView(entry: entries[2], rank: 3)) {
                podiumColumn(entry: entries[2], rank: 3, height: 120, color: Color(red: 0.8, green: 0.5, blue: 0.2)) // Bronze
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, 20)
    }
    
    func podiumColumn(entry: LeaderboardEntry, rank: Int, height: CGFloat, color: Color) -> some View {
        VStack(spacing: 8) {
            // Avatar Circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: rank == 1 ? 90 : 74, height: rank == 1 ? 90 : 74)
                
                Image("default-avatar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: rank == 1 ? 70 : 58, height: rank == 1 ? 70 : 58)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: rank == 1 ? 3 : 2)
                    )
                    .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                
                // Rank Badge
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(color)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(y: rank == 1 ? 40 : 32)
                
                if rank == 1 {
                    SymbolStickerView(symbol: "crown.fill", size: 28, colors: [.orange, .yellow])
                        .offset(y: -48)
                }
            }
            
            // User Info
            VStack(spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(formattedScore(for: entry))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            // Podium Bar
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.8),
                                color.opacity(0.4),
                                color.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Shimmer/Shine Effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Top Highlight
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            }
            .frame(height: height)
            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(
                format: localization.localized("leaderboard_row_accessibility"),
                rank,
                entry.name,
                formattedScore(for: entry)
            )
        )
    }
}

// MARK: - Remaining List
private extension LeaderboardView {
    var remainingList: some View {
        let entries = leaderboardService.topEntries
        let showPodium = entries.count >= 3
        let listEntries = showPodium ? Array(entries.dropFirst(3)) : entries
        let startRank = showPodium ? 4 : 1
        
        return LazyVStack(spacing: 12) {
            ForEach(Array(listEntries.enumerated()), id: \.element.id) { offset, entry in
                NavigationLink(destination: UserProfileView(entry: entry, rank: startRank + offset)) {
                    leaderboardRow(entry: entry, rank: startRank + offset)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
    
    func leaderboardRow(entry: LeaderboardEntry, rank: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
                .frame(width: 20)
            
            ZStack {
                Circle()
                    .fill(design.accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image("default-avatar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(design.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                if entry.isCurrentUser {
                    Text(localization.localized("leaderboard_you_label"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(design.accentColor)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(scoreValue(for: entry))")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(scoreLabel())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(design.accentColor.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .streetBeastSurface()
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .stroke(entry.isCurrentUser ? design.accentColor.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
        )
        .streetBeastGlow(entry.isCurrentUser ? design.accentColor.opacity(0.3) : .clear, radius: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(
                format: localization.localized("leaderboard_row_accessibility"),
                rank,
                entry.name,
                formattedScore(for: entry)
            )
        )
        .accessibilityHint(localization.localized("leaderboard_row_accessibility_hint"))
    }
}

// MARK: - Current User Sticky Bar
private extension LeaderboardView {
    var currentUserStickyBar: some View {
        VStack {
            Spacer()
            if let userEntry = leaderboardService.topEntries.first(where: { $0.isCurrentUser }),
               let index = leaderboardService.topEntries.firstIndex(where: { $0.id == userEntry.id }),
               index >= 3 {
                
                HStack(spacing: 16) {
                    Text("\(index + 1)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(design.accentColor)
                        .clipShape(Circle())
                    
                    Text(localization.localized("leaderboard_encouragement"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(scoreValue(for: userEntry))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(scoreLabel())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(red: 0.18, green: 0.22, blue: 0.42).opacity(0.92))
                .background(design.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [design.accentColor.opacity(0.6), design.accentColor.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .streetBeastGlow(design.accentColor, radius: 8)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, 24)
                .transition(.streetBeastSlideUp)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    String(
                        format: localization.localized("leaderboard_sticky_accessibility"),
                        index + 1,
                        formattedScore(for: userEntry)
                    )
                )
            }
        }
    }
}

// MARK: - Loading State
private extension LeaderboardView {
    var staleDataBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 12, weight: .bold))
            Text(localization.localized("leaderboard_stale_data"))
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white.opacity(0.85))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.25))
        .clipShape(Capsule())
        .padding(.top, 8)
        .accessibilityLabel(localization.localized("leaderboard_stale_data"))
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(design.secondaryTextColor.opacity(0.7))

            Text(localization.localized("leaderboard_empty"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxHeight: .infinity)
    }

    var errorState: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.orange)

            Text(localization.localized("leaderboard_error_title"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(localization.localized("leaderboard_error_subtitle"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(design.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task {
                    await leaderboardService.fetchLeaderboard()
                }
            } label: {
                Text(localization.localized("leaderboard_retry"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(design.accentColor)
                    .clipShape(Capsule())
            }
            .accessibilityHint(localization.localized("leaderboard_retry_hint"))
        }
        .frame(maxHeight: .infinity)
    }

    var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(design.accentColor)
                .scaleEffect(1.5)
            
            Text(localization.localized("leaderboard_loading"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    LeaderboardView()
}
