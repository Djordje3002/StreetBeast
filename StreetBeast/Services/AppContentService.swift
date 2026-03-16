import Foundation
import FirebaseFirestore

final class AppContentService {
    static let shared = AppContentService()

    private let db: Firestore?
    private let userDefaults: UserDefaults
    private let analytics: AnalyticsService
    private let lock = NSLock()

    private let challengesCacheKey = "content_cache_challenges_v1"
    private let chatPromptCacheKey = "content_cache_chat_prompt_v1"
    private let lastRefreshKey = "content_cache_last_refresh_at"
    private let contentVersionCacheKey = "content_cache_version"
    private let refreshInterval: TimeInterval = 60 * 30

    private var challenges: [SocialChallenge]
    private var chatPrompt: String?
    private var contentVersion: String?

    init(
        db: Firestore? = Firestore.firestore(),
        userDefaults: UserDefaults = .standard,
        analytics: AnalyticsService = .shared
    ) {
        self.db = db
        self.userDefaults = userDefaults
        self.analytics = analytics

        let cachedChallenges = Self.decodeCache([SocialChallenge].self, from: userDefaults.data(forKey: challengesCacheKey))
        let cachedChatPrompt = userDefaults.string(forKey: chatPromptCacheKey)
        let cachedContentVersion = userDefaults.string(forKey: contentVersionCacheKey)
        self.challenges = Self.nonEmptyOrFallback(cachedChallenges, fallback: SocialChallenge.initialChallenges)
        self.chatPrompt = Self.normalizedPrompt(cachedChatPrompt)
        self.contentVersion = Self.normalizedPrompt(cachedContentVersion)
    }

    var challengesSnapshot: [SocialChallenge] {
        lock.withLock { challenges }
    }

    var chatSystemPromptSnapshot: String? {
        lock.withLock { chatPrompt }
    }

    var contentVersionSnapshot: String? {
        lock.withLock { contentVersion }
    }

    @discardableResult
    func refreshFromBackendIfNeeded(force: Bool = false) async -> Bool {
        guard let db else { return false }
        let now = Date()

        do {
            async let metaDoc = db.collection("app_content").document("meta").getDocument()
            async let challengesDoc = db.collection("app_content").document("daily_challenges").getDocument()
            async let chatPromptDoc = db.collection("app_content").document("chat_prompt").getDocument()

            let metaSnapshot = try await metaDoc
            let remoteVersion = decodeContentVersion(from: metaSnapshot.data())
            let cachedVersion = contentVersionSnapshot

            if !force,
               shouldSkipRefresh(
                lastRefresh: userDefaults.object(forKey: lastRefreshKey) as? Date,
                now: now,
                cachedVersion: cachedVersion,
                remoteVersion: remoteVersion
               ) {
                return false
            }

            let (challengeSnapshot, chatPromptSnapshot) = try await (challengesDoc, chatPromptDoc)

            var didUpdateAny = false

            if let data = challengeSnapshot.data(),
               let decoded: [SocialChallenge] = decodeArrayContent(from: data),
               !decoded.isEmpty {
                lock.withLock {
                    challenges = decoded
                }
                cache(decoded, key: challengesCacheKey)
                didUpdateAny = true
            }

            if let data = chatPromptSnapshot.data(),
               let prompt = decodePrompt(from: data) {
                lock.withLock {
                    chatPrompt = prompt
                }
                userDefaults.set(prompt, forKey: chatPromptCacheKey)
                didUpdateAny = true
            }

            if let remoteVersion {
                lock.withLock { contentVersion = remoteVersion }
                userDefaults.set(remoteVersion, forKey: contentVersionCacheKey)
            }

            userDefaults.set(now, forKey: lastRefreshKey)
            if didUpdateAny {
                analytics.track(
                    "content_refresh_success",
                    metadata: [
                        "version": remoteVersion ?? cachedVersion ?? "unknown"
                    ]
                )
            }
            return didUpdateAny
        } catch {
            analytics.error("content_refresh_failed", message: error.localizedDescription)
            userDefaults.set(now, forKey: lastRefreshKey)
            return false
        }
    }

    private func cache<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            userDefaults.set(data, forKey: key)
        }
    }

    private static func decodeCache<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func nonEmptyOrFallback<T>(_ value: [T]?, fallback: [T]) -> [T] {
        guard let value, !value.isEmpty else { return fallback }
        return value
    }

    private static func normalizedPrompt(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func decodeArrayContent<T: Decodable>(from data: [String: Any]) -> [T]? {
        let keys = ["items", "content", "data", "payload"]

        for key in keys {
            if let value = data[key], let decoded: [T] = decodeJSONArray(from: value) {
                return decoded
            }
            if let jsonString = data[key] as? String, let decoded: [T] = decodeJSONArray(fromJSONString: jsonString) {
                return decoded
            }
        }

        return nil
    }

    private func decodePrompt(from data: [String: Any]) -> String? {
        let keys = ["systemPrompt", "system_prompt", "prompt", "text", "value"]
        for key in keys {
            if let value = data[key] as? String,
               let normalized = Self.normalizedPrompt(value) {
                return normalized
            }
        }
        return nil
    }

    private func decodeContentVersion(from data: [String: Any]?) -> String? {
        guard let data else { return nil }
        let keys = ["contentVersion", "content_version", "version"]
        for key in keys {
            if let value = data[key] as? String,
               let normalized = Self.normalizedPrompt(value) {
                return normalized
            }
        }
        if let value = data["version"] as? Int {
            return String(value)
        }
        return nil
    }

    private func shouldSkipRefresh(
        lastRefresh: Date?,
        now: Date,
        cachedVersion: String?,
        remoteVersion: String?
    ) -> Bool {
        guard let lastRefresh else { return false }

        // If backend version changed, refresh immediately regardless of interval.
        if let remoteVersion,
           let cachedVersion,
           remoteVersion != cachedVersion {
            return false
        }

        return now.timeIntervalSince(lastRefresh) < refreshInterval
    }

    private func decodeJSONArray<T: Decodable>(from value: Any) -> [T]? {
        guard JSONSerialization.isValidJSONObject(value),
              let jsonData = try? JSONSerialization.data(withJSONObject: value),
              let decoded = try? JSONDecoder().decode([T].self, from: jsonData) else {
            return nil
        }
        return decoded
    }

    private func decodeJSONArray<T: Decodable>(fromJSONString jsonString: String) -> [T]? {
        guard let data = jsonString.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([T].self, from: data) else {
            return nil
        }
        return decoded
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
