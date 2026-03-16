import Foundation

final class MaxStrengthSyncService {
    static let shared = MaxStrengthSyncService()

    private let userDefaults: UserDefaults
    private let pendingKey = "pendingMaxStrengthPayload"
    private let analytics = AnalyticsService.shared

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func enqueue(_ value: MaxStrength) {
        guard let encoded = try? JSONEncoder().encode(value) else { return }
        userDefaults.set(encoded, forKey: pendingKey)
        analytics.track("max_strength_sync_queued")
    }

    func hasPendingPayload() -> Bool {
        userDefaults.data(forKey: pendingKey) != nil
    }

    func clearPending() {
        userDefaults.removeObject(forKey: pendingKey)
    }

    @discardableResult
    func flushIfPossible(uid: String?) async -> Bool {
        guard let uid, let data = userDefaults.data(forKey: pendingKey),
              let payload = try? JSONDecoder().decode(MaxStrength.self, from: data) else {
            return false
        }

        do {
            try await AuthService.shared.updateMaxStrength(payload, for: uid)
            userDefaults.removeObject(forKey: pendingKey)
            analytics.track("max_strength_sync_flushed")
            return true
        } catch {
            analytics.error("max_strength_sync_failed", message: error.localizedDescription)
            return false
        }
    }
}
