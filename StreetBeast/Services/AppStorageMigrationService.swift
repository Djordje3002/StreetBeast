import Foundation

final class AppStorageMigrationService {
    static let shared = AppStorageMigrationService()
    
    private let userDefaults: UserDefaults
    private let schemaVersionKey = "appSchemaVersion"
    private let currentSchemaVersion = 1
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func runMigrationsIfNeeded() {
        let version = userDefaults.integer(forKey: schemaVersionKey)
        guard version < currentSchemaVersion else { return }
        
        if version < 1 {
            migrateToV1()
        }
        
        userDefaults.set(currentSchemaVersion, forKey: schemaVersionKey)
    }
    
    private func migrateToV1() {
        // Guard against invalid notification preference values from older builds.
        if let rawValue = userDefaults.string(forKey: "notificationPreference"),
           NotificationPreference(rawValue: rawValue) == nil {
            userDefaults.set(NotificationPreference.off.rawValue, forKey: "notificationPreference")
        }
        
        // Normalize old challenge key naming if needed.
        if userDefaults.object(forKey: "totalChallengesCompleted") == nil,
           let legacyValue = userDefaults.object(forKey: "totalVersesCollected") as? Int {
            userDefaults.set(legacyValue, forKey: "totalChallengesCompleted")
        }
    }
}
