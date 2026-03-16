import UserNotifications
import UIKit

// MARK: - Models

enum NotificationPreference: String, Codable, CaseIterable {
    case morning
    case evening
    case off
    
    var title: String {
        switch self {
        case .morning: return LocalizationManager.shared.localized("notification_pref_morning")
        case .evening: return LocalizationManager.shared.localized("notification_pref_evening")
        case .off: return LocalizationManager.shared.localized("notification_pref_off")
        }
    }
}

// MARK: - Notification Service

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    static let deepLinkNotification = Notification.Name("streetbeast.notification.deepLink")
    static let todayChallengeDeepLink = "today_challenge"
    
    private let center = UNUserNotificationCenter.current()
    private let preferenceKey = "notificationPreference"
    private let reminderIdentifier = "daily_challenge_reminder"
    private let deepLinkKey = "deep_link_target"
    private var pendingDeepLink: String?
    private let analytics = AnalyticsService.shared
    
    private override init() {}
    
    // MARK: - Public API
    
    func configure() {
        center.delegate = self
        Task {
            await restoreScheduleIfNeeded()
        }
    }
    
    func getPreference() -> NotificationPreference? {
        guard let string = UserDefaults.standard.string(forKey: preferenceKey) else {
            return nil
        }
        return NotificationPreference(rawValue: string)
    }
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    @discardableResult
    func applyOnboardingPreference(_ preference: NotificationPreference) async -> Bool {
        let enabled = await applyPreference(preference, requestIfNeeded: true)
        analytics.track(
            "notification_onboarding_choice",
            metadata: [
                "preference": preference.rawValue,
                "enabled": enabled ? "true" : "false"
            ]
        )
        return enabled
    }
    
    @discardableResult
    func applyPreference(_ preference: NotificationPreference, requestIfNeeded: Bool) async -> Bool {
        if preference == .off {
            disableNotifications()
            return false
        }
        
        let status = await getAuthorizationStatus()
        
        switch status {
        case .authorized, .provisional, .ephemeral:
            savePreference(preference)
            return true
        case .notDetermined:
            guard requestIfNeeded else {
                disableNotifications()
                return false
            }
            let granted = await requestPermission()
            if granted {
                savePreference(preference)
                return true
            } else {
                disableNotifications()
                return false
            }
        case .denied:
            disableNotifications()
            return false
        @unknown default:
            disableNotifications()
            return false
        }
    }
    
    func disableNotifications() {
        savePreference(.off)
    }
    
    func openAppNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
        analytics.track("notification_open_settings")
    }
    
    func consumePendingDeepLink() -> String? {
        let value = pendingDeepLink
        pendingDeepLink = nil
        return value
    }
    
    func peekPendingDeepLink() -> String? {
        pendingDeepLink
    }
    
    // MARK: - Internal Scheduling
    
    private func savePreference(_ preference: NotificationPreference) {
        UserDefaults.standard.set(preference.rawValue, forKey: preferenceKey)
        schedule(for: preference)
    }
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }
    
    private func schedule(for preference: NotificationPreference) {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        
        guard preference != .off else { return }
        
        let content = UNMutableNotificationContent()
        content.title = LocalizationManager.shared.localized("notification_title")
        content.body = LocalizationManager.shared.localized("notification_body")
        content.sound = .default
        content.userInfo = [deepLinkKey: Self.todayChallengeDeepLink]
        
        var dateComponents = DateComponents()
        dateComponents.hour = (preference == .morning) ? 8 : 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                self.analytics.error("notification_schedule", message: error.localizedDescription)
                print("Error scheduling notification: \(error)")
            } else {
                self.analytics.track("notification_scheduled", metadata: ["preference": preference.rawValue])
            }
        }
    }
    
    private func restoreScheduleIfNeeded() async {
        guard let preference = getPreference(), preference != .off else { return }
        let status = await getAuthorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }
        schedule(for: preference)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleDeepLink(from: response.notification.request.content.userInfo)
        completionHandler()
    }
    
    private func handleDeepLink(from userInfo: [AnyHashable: Any]) {
        guard let deepLink = userInfo[deepLinkKey] as? String else { return }
        pendingDeepLink = deepLink
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.deepLinkNotification, object: deepLink)
        }
    }
}
