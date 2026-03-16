import SwiftUI
import Combine
import UserNotifications

class SettingsViewModel: ObservableObject {
    @Published var showLogoutAlert = false
    @Published var notificationPreference: NotificationPreference = .off
    @Published var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isUpdatingNotifications = false
    
    // Dependencies
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject var localization = LocalizationManager.shared
    private let notificationService = NotificationService.shared
    
    // MARK: - Language Management
    
    func selectLanguage(_ language: Language) {
        withAnimation(.easeInOut(duration: 0.3)) {
            localization.currentLanguage = language
        }
    }
    
    // MARK: - Logout
    
    func requestLogout() {
        showLogoutAlert = true
    }
    
    func confirmLogout() {
        authManager.logout()
    }
    
    // MARK: - User Info
    
    var userName: String {
        authManager.currentUser?.preferredDisplayName ?? localization.localized("user_unknown")
    }
    
    var userEmail: String {
        authManager.currentUser?.email ?? ""
    }
    
    var notificationStatusText: String {
        switch notificationAuthorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return localization.localized("settings_notifications_status_on")
        case .denied:
            return localization.localized("settings_notifications_status_denied")
        case .notDetermined:
            return localization.localized("settings_notifications_status_not_determined")
        @unknown default:
            return localization.localized("settings_notifications_status_unknown")
        }
    }
    
    func loadNotificationSettings() async {
        let status = await notificationService.getAuthorizationStatus()
        let preference = notificationService.getPreference() ?? .off
        await MainActor.run {
            notificationAuthorizationStatus = status
            notificationPreference = preference
        }
    }
    
    func selectNotificationPreference(_ preference: NotificationPreference) async {
        await MainActor.run { isUpdatingNotifications = true }
        let enabled = await notificationService.applyPreference(preference, requestIfNeeded: true)
        let status = await notificationService.getAuthorizationStatus()
        
        await MainActor.run {
            notificationAuthorizationStatus = status
            notificationPreference = enabled ? preference : .off
            isUpdatingNotifications = false
        }
    }
    
    func openNotificationSettings() {
        notificationService.openAppNotificationSettings()
    }
}
