import Foundation

final class OnboardingSyncService {
    static let shared = OnboardingSyncService()
    
    private let userDefaults: UserDefaults
    private let pendingOnboardingKey = "pendingOnboardingPayload"
    private let analytics = AnalyticsService.shared
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func enqueue(_ data: OnboardingResponse) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        userDefaults.set(encoded, forKey: pendingOnboardingKey)
        analytics.track("onboarding_sync_queued")
    }
    
    func hasPendingPayload() -> Bool {
        userDefaults.data(forKey: pendingOnboardingKey) != nil
    }
    
    @discardableResult
    func flushIfPossible(uid: String?) async -> Bool {
        guard let uid, let data = userDefaults.data(forKey: pendingOnboardingKey) else {
            return false
        }
        
        do {
            let payload = try JSONDecoder().decode(OnboardingResponse.self, from: data)
            try await AuthService.shared.saveOnboardingData(payload, for: uid)
            userDefaults.removeObject(forKey: pendingOnboardingKey)
            analytics.track("onboarding_sync_flushed")
            return true
        } catch {
            analytics.error("onboarding_sync_flush_failed", message: error.localizedDescription)
            return false
        }
    }
}
