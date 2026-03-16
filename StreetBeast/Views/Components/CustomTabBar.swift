import SwiftUI

enum Tab: Int, CaseIterable, Identifiable {
    case timer = 0
    case progress = 1
    case leaderboard = 2
    case settings = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .timer: return LocalizationManager.shared.localized("tab_timer")
        case .progress: return LocalizationManager.shared.localized("tab_progress")
        case .leaderboard: return LocalizationManager.shared.localized("tab_leaderboard")
        case .settings: return LocalizationManager.shared.localized("tab_settings")
        }
    }

    var icon: String {
        switch self {
        case .timer: return "timer"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .leaderboard: return "trophy.fill"
        case .settings: return "gearshape"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @ObservedObject private var design = DesignSystem.shared
    @State private var tabPulseScale: [Tab: CGFloat] = [:]
    @Namespace private var tabSelectionAnimation

    var body: some View {
        HStack(spacing: 11) {
            ForEach(Tab.allCases) { tab in
                Button {
                    select(tab: tab)
                } label: {
                    tabItem(for: tab)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(design.paperColor.opacity(0.95))
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(design.accentColor.opacity(0.18), lineWidth: 1)
        )
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: selectedTab)
    }

    private func tabItem(for tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        let pulseScale = tabPulseScale[tab] ?? 1.0

        return HStack(spacing: 8) {
            Image(systemName: tab.icon)
                .font(.system(size: isSelected ? 17 : 16, weight: isSelected ? .semibold : .medium))

            if isSelected {
                Text(tab.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .foregroundStyle(isSelected ? Color.white : design.secondaryTextColor)
        .frame(height: 48)
        .frame(minWidth: isSelected ? 124 : 50)
        .padding(.horizontal, isSelected ? 15 : 0)
        .background {
            if isSelected {
                Capsule(style: .continuous)
                    .fill(selectedGradient)
                    .matchedGeometryEffect(id: "selectedTabBackground", in: tabSelectionAnimation)
            } else {
                Capsule(style: .continuous)
                    .fill(Color.clear)
            }
        }
        .overlay {
            if isSelected {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            }
        }
        .scaleEffect((isSelected ? 1.0 : 0.92) * pulseScale)
        .contentShape(Capsule(style: .continuous))
    }

    private var selectedGradient: LinearGradient {
        LinearGradient(
            colors: [design.accentColor, design.flameColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func select(tab: Tab) {
        triggerPulse(for: tab)

        guard tab != selectedTab else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            return
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
            selectedTab = tab
        }
    }

    private func triggerPulse(for tab: Tab) {
        tabPulseScale[tab] = 1.0

        withAnimation(.spring(response: 0.18, dampingFraction: 0.58)) {
            tabPulseScale[tab] = 1.12
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
                tabPulseScale[tab] = 1.0
            }
        }
    }
}

#Preview {
    ZStack {
        DesignSystem.shared.backgroundColor.ignoresSafeArea()
        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(.timer))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }
}
