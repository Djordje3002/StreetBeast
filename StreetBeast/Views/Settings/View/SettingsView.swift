import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        ScreenScaffold(
            contentTopPadding: 120,
            horizontalPadding: DesignSystem.Spacing.lg * 1.2,
            bottomPadding: 140,
            header: {
                EmptyView()
            },
            content: {
                VStack(spacing: 32) {
                    profileCard
                    generalSection
                    aboutSection
                    leaderboardCard
                    logoutButton
                }
            }
        )
        .navigationBarHidden(true)
        .alert(localization.localized("log_out_title"), isPresented: $viewModel.showLogoutAlert) {
            Button(localization.localized("cancel"), role: .cancel) { }
            Button(localization.localized("log_out_action"), role: .destructive) {
                viewModel.confirmLogout()
            }
        } message: {
            Text(localization.localized("log_out_confirmation"))
        }
        .task {
            await viewModel.loadNotificationSettings()
        }
        .dynamicTypeSize(.medium ... .accessibility3)
    }
}

// MARK: - Profile Card
private extension SettingsView {
    var profileCard: some View {
        NavigationLink(destination: ProfileView()) {
            NavigationSurfaceCard(
                spacing: DesignSystem.Spacing.md,
                horizontalPadding: DesignSystem.Spacing.lg,
                verticalPadding: DesignSystem.Spacing.lg,
                style: .clean,
                leading: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [design.accentColor, design.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image("default-avatar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .shadow(color: design.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                },
                content: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.userName)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(design.textColor)
                        
                        Text(viewModel.userEmail)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(design.secondaryTextColor)
                    }
                }
            )
        }
    }
}

// MARK: - General Section
private extension SettingsView {
    var generalSection: some View { 
        SectionBlock(title: localization.localized("general_section")) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(Language.allCases, id: \.self) { language in
                    LanguageOptionButton(
                        language: language,
                        isSelected: localization.currentLanguage == language,
                        action: {
                            viewModel.selectLanguage(language)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - About Section
private extension SettingsView {
    var aboutSection: some View {
        let externalLinkRows: [(icon: String, title: String, url: String)] = [
            ("hand.raised.fill", localization.localized("privacy_policy"), AppLinks.privacyPolicy),
            ("doc.text.fill", localization.localized("terms_of_service"), AppLinks.termsOfService)
        ]
        
        return SectionBlock(title: localization.localized("about_section")) {
            SettingsCardGroup {
                settingRow(icon: "number.circle.fill", title: localization.localized("version"), value: "1.0.0")
                SettingsRowDivider()
                
                ForEach(Array(externalLinkRows.enumerated()), id: \.offset) { index, row in
                    settingLink(icon: row.icon, title: row.title, url: row.url)
                    
                    if index < externalLinkRows.count - 1 {
                        SettingsRowDivider()
                    }
                }

                if !externalLinkRows.isEmpty {
                    SettingsRowDivider()
                }

                NavigationLink(destination: SupportView()) {
                    settingNavigationContent(icon: "lifepreserver.fill", title: localization.localized("support"))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    func settingRow(icon: String, title: String, value: String) -> some View {
        SettingsListRow(icon: icon, title: title) {
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(design.secondaryTextColor)
        }
    }
    
    @ViewBuilder
    func settingLink(icon: String, title: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                settingLinkContent(icon: icon, title: title)
            }
        } else {
            settingLinkContent(icon: icon, title: title)
                .opacity(0.6)
        }
    }
    
    func settingLinkContent(icon: String, title: String) -> some View {
        SettingsListRow(icon: icon, title: title) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(design.secondaryTextColor)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(localization.localized("settings_open_link_hint"))
        .accessibilityAddTraits(.isButton)
    }

    func settingNavigationContent(icon: String, title: String) -> some View {
        SettingsListRow(icon: icon, title: title) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(design.secondaryTextColor)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(localization.localized("settings_open_support_hint"))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Logout Button
private extension SettingsView {
    var logoutButton: some View {
        Button(action: {
            viewModel.requestLogout()
        }) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(localization.localized("log_out_action"))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .foregroundColor(design.paperColor)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: [design.accentColor, design.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: design.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.top, DesignSystem.Spacing.md)
    }
}

// MARK: - Leaderboard Card
private extension SettingsView {
    var leaderboardCard: some View {
        SectionBlock(title: localization.localized("profile_leaderboard_title")) {
            NavigationLink(destination: LeaderboardView()) {
                HStack(spacing: 12) {
                    // Visual Elements
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.12), .orange.opacity(0.06)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 65, height: 65)
                        
                        // Trophy Icons Trio
                        HStack(spacing: -10) {
                            SymbolStickerView(
                                symbol: "trophy.fill",
                                size: 28,
                                colors: [.gray, .white.opacity(0.8)],
                                backgroundColor: design.paperColor,
                                isSimple: true
                            )
                            .offset(y: 3)
                            .scaleEffect(0.85)
                            
                            SymbolStickerView(
                                symbol: "trophy.fill",
                                size: 38,
                                colors: [.orange, .yellow],
                                backgroundColor: design.paperColor,
                                isSimple: true
                            )
                            .zIndex(1)
                            
                            SymbolStickerView(
                                symbol: "trophy.fill",
                                size: 28,
                                colors: [.brown, .orange.opacity(0.8)],
                                backgroundColor: design.paperColor,
                                isSimple: true
                            )
                            .offset(y: 3)
                            .scaleEffect(0.85)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.localized("settings_leaderboard_title"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(design.textColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        
                        Text(localization.localized("settings_leaderboard_desc"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(design.secondaryTextColor)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.9)
                    }
                    
                    Spacer()
                    
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(design.secondaryTextColor)
            }
            .padding(DesignSystem.Spacing.lg)
            .settingsCardSurface()
        }
    }
}
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(DesignSystem.shared)
        .environmentObject(AuthManager.shared)
}
