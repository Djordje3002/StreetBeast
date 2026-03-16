import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .timer
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var headerStreak: Int = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ZStack {
                    TimerView()
                        .opacity(selectedTab == .timer ? 1 : 0)
                        .allowsHitTesting(selectedTab == .timer)

                    ProgressHubView()
                        .opacity(selectedTab == .progress ? 1 : 0)
                        .allowsHitTesting(selectedTab == .progress)

                    LeaderboardTabView()
                        .opacity(selectedTab == .leaderboard ? 1 : 0)
                        .allowsHitTesting(selectedTab == .leaderboard)

                    SettingsView()
                        .opacity(selectedTab == .settings ? 1 : 0)
                        .allowsHitTesting(selectedTab == .settings)
                }

                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
            }
            .overlay(alignment: .top) {
                CustomNavigationBar(title: headerTitle, streak: headerStreak)
                    .zIndex(1)
            }
            .background(design.backgroundColor.ignoresSafeArea())
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await loadHeaderStreak()
            }
            .onChange(of: authManager.currentUser?.id) { _, _ in
                Task {
                    await loadHeaderStreak()
                }
            }
        }
    }

    private var headerTitle: String {
        switch selectedTab {
        case .timer:
            return localization.localized("timer_title")
        case .progress:
            return localization.localized("progress_title")
        case .leaderboard:
            return localization.localized("leaderboard_screen_title")
        case .settings:
            return localization.localized("settings_title")
        }
    }

    @MainActor
    private func loadHeaderStreak() async {
        do {
            let response = try await UserService.shared.getStreak()
            headerStreak = response.currentStreak
        } catch {
            headerStreak = 0
        }
    }
}

#Preview {
    MainTabView()
}
