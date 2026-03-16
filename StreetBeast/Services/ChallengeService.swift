import Foundation

struct DailyChallengeResponse {
    let challenge: SocialChallenge
    let date: String
    let completed: Bool
}

final class ChallengeService: ChallengeServicing {
    static let shared = ChallengeService()
    private let analytics = AnalyticsService.shared
    private let userDefaults: UserDefaults
    private let authSession: AuthSessionProviding
    private let completionLogger: ChallengeCompletionLogging
    private let challengesProvider: () -> [SocialChallenge]
    private let calendar: Calendar
    private let now: () -> Date
    
    init(
        userDefaults: UserDefaults = .standard,
        authSession: AuthSessionProviding = FirebaseAuthSessionProvider(),
        completionLogger: ChallengeCompletionLogging = UserService.shared,
        contentService: AppContentService = .shared,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.userDefaults = userDefaults
        self.authSession = authSession
        self.completionLogger = completionLogger
        self.challengesProvider = { [weak contentService] in
            contentService?.challengesSnapshot ?? []
        }
        self.calendar = calendar
        self.now = now
    }
    
    // MARK: - Constants
    private let completedChallengeByDateKeyBase = "completedChallengeByDate"
    private let legacyCompletedChallengesKeyBase = "completedChallenges"
    private let challengeScheduleStartDayKeyBase = "challengeScheduleStartDay"
    // MARK: - Daily Challenge
    
    func getDailyChallenge() async -> DailyChallengeResponse {
        let today = now()
        let formatter = ISO8601DateFormatter()
        
        // Deterministic per-user schedule: each user starts from easiest challenge.
        let safeChallenges = normalizedChallenges()
        var challenge = scheduledChallenge(for: today, challenges: safeChallenges)
        
        // Configure title/description based on user language? 
        // Better to return the full object and let view handle localization
        
        // Check if today's challenge is completed
        let todayKey = dayKey(for: today)
        let completedByDate = getCompletedChallengeByDate()
        challenge.isCompleted = completedByDate[todayKey] == challenge.id
        ChallengeWidgetSync.persist(challenge: challenge, date: today, calendar: calendar)
        
        return DailyChallengeResponse(
            challenge: challenge,
            date: formatter.string(from: today),
            completed: challenge.isCompleted
        )
    }
    
    // MARK: - Challenge Management
    
    func completeChallenge(id: String) {
        let todayKey = dayKey(for: now())
        var completedByDate = getCompletedChallengeByDate()
        
        // Only one completion is counted per day.
        guard completedByDate[todayKey] == nil else { return }
        
        completedByDate[todayKey] = id
        saveCompletedChallengeByDate(completedByDate)
        analytics.track("challenge_marked_completed", metadata: ["challenge_id": id, "day": todayKey])
        
        // Also notify UserService to update streaks
        Task {
            await completionLogger.logChallengeCompletion()
        }
    }
    
    func isChallengeCompleted(id: String) -> Bool {
        let todayKey = dayKey(for: now())
        return getCompletedChallengeByDate()[todayKey] == id
    }
    
    // MARK: - Helpers
    
    private func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func getCompletedChallengeByDate() -> [String: String] {
        let scopedByDateKey = scopedKey(completedChallengeByDateKeyBase)
        var completedByDate = userDefaults.dictionary(forKey: scopedByDateKey) as? [String: String] ?? [:]
        
        // One-time migration from legacy global ID list.
        if completedByDate.isEmpty,
           let legacyIds = userDefaults.stringArray(forKey: scopedKey(legacyCompletedChallengesKeyBase)),
           legacyIds.contains(todayChallengeId()) {
            completedByDate[dayKey(for: now())] = todayChallengeId()
            saveCompletedChallengeByDate(completedByDate)
        }
        
        return completedByDate
    }
    
    private func saveCompletedChallengeByDate(_ completedByDate: [String: String]) {
        userDefaults.set(completedByDate, forKey: scopedKey(completedChallengeByDateKeyBase))
    }
    
    private func todayChallengeId() -> String {
        let challenges = normalizedChallenges()
        return scheduledChallenge(for: now(), challenges: challenges).id
    }

    private func normalizedChallenges() -> [SocialChallenge] {
        let challenges = challengesProvider()
        let source = challenges.isEmpty ? SocialChallenge.initialChallenges : challenges
        return source.sorted {
            if $0.difficultyLevel == $1.difficultyLevel {
                return $0.id < $1.id
            }
            return $0.difficultyLevel < $1.difficultyLevel
        }
    }

    private func scheduledChallenge(for date: Date, challenges: [SocialChallenge]) -> SocialChallenge {
        guard !challenges.isEmpty else {
            return SocialChallenge.initialChallenges[0]
        }

        let startDay = challengeScheduleStartDay(defaultingTo: date)
        let currentDay = calendar.startOfDay(for: date)
        let daysOffset = calendar.dateComponents([.day], from: startDay, to: currentDay).day ?? 0
        let safeOffset = max(daysOffset, 0)
        let index = safeOffset % challenges.count
        return challenges[index]
    }

    private func challengeScheduleStartDay(defaultingTo date: Date) -> Date {
        let key = scopedKey(challengeScheduleStartDayKeyBase)
        if let dayKey = userDefaults.string(forKey: key),
           let parsed = dateFromDayKey(dayKey) {
            return calendar.startOfDay(for: parsed)
        }

        let startDay = calendar.startOfDay(for: date)
        userDefaults.set(dayKey(for: startDay), forKey: key)
        return startDay
    }

    private func dateFromDayKey(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    private var storageUserScope: String {
        authSession.currentUserId ?? "guest"
    }

    private func scopedKey(_ base: String) -> String {
        "\(base).\(storageUserScope)"
    }
}
