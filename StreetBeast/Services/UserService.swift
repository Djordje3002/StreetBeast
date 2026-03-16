import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol AuthSessionProviding {
    var currentUserId: String? { get }
}

struct FirebaseAuthSessionProvider: AuthSessionProviding {
    var currentUserId: String? { Auth.auth().currentUser?.uid }
}

protocol UserRemoteSyncing {
    func syncChallengeCompletion(date: Date, uid: String) async throws
    func fetchCollectionDates(uid: String, daysBack: Int) async throws -> [Date]
}

final class FirestoreUserRemoteSync: UserRemoteSyncing {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func syncChallengeCompletion(date: Date, uid: String) async throws {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"

        let dayKey = formatter.string(from: date)
        let userRef = db.collection("users").document(uid)
        let collectionDocRef = db.collection("users")
            .document(uid)
            .collection("collections")
            .document(dayKey)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.runTransaction({ transaction, errorPointer in
                do {
                    let existingCollectionDoc = try transaction.getDocument(collectionDocRef)

                    // Idempotency guard: if today's collection already exists, skip counter increments.
                    if existingCollectionDoc.exists {
                        return nil
                    }

                    let now = Timestamp(date: Date())
                    transaction.setData([
                        "date": Timestamp(date: date),
                        "type": "social_challenge"
                    ], forDocument: collectionDocRef, merge: true)

                    transaction.setData([
                        "totalChallengesCompleted": FieldValue.increment(Int64(1)),
                        // Temporary mirrored field for backward compatibility with legacy clients.
                        "totalVersesCollected": FieldValue.increment(Int64(1)),
                        "lastChallengeCompletedAt": now,
                        // Temporary mirrored field for backward compatibility with legacy clients.
                        "lastVerseCollectedAt": now
                    ], forDocument: userRef, merge: true)

                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func fetchCollectionDates(uid: String, daysBack: Int = 90) async throws -> [Date] {
        let collectionRef = db.collection("users").document(uid).collection("collections")
        let cutoff = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let snapshot = try await collectionRef
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: cutoff))
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            (doc.data()["date"] as? Timestamp)?.dateValue()
        }
    }
}

class UserService: UserServicing, ChallengeCompletionLogging {
    static let shared = UserService()
    private let analytics: AnalyticsService
    private let userDefaults: UserDefaults
    private let authSession: AuthSessionProviding
    private let remoteSync: UserRemoteSyncing
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private let retryInitialDelayNanos: UInt64

    init(
        userDefaults: UserDefaults = .standard,
        authSession: AuthSessionProviding = FirebaseAuthSessionProvider(),
        remoteSync: UserRemoteSyncing = FirestoreUserRemoteSync(),
        analytics: AnalyticsService = .shared,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init,
        retryInitialDelayNanos: UInt64 = 400_000_000
    ) {
        self.userDefaults = userDefaults
        self.authSession = authSession
        self.remoteSync = remoteSync
        self.analytics = analytics
        self.calendar = calendar
        self.now = now
        self.retryInitialDelayNanos = retryInitialDelayNanos
    }

    private let collectionDatesKeyBase = "collectionDates"
    private let totalChallengesCompletedKeyBase = "totalChallengesCompleted"
    private let pendingRemoteSyncDaysKeyBase = "pendingRemoteChallengeSyncDays"
    private let completionEventLogKeyBase = "challengeCompletionEventLogV1"
    // MARK: - Public API

    func getStreak() async throws -> StreakResponse {
        var dates = loadCollectionDates()

        // If authenticated, merge in Firestore collection dates for cross-device consistency.
        if let uid = authSession.currentUserId {
            await flushPendingRemoteSyncDays(uid: uid)
            do {
                let remoteDates = try await remoteSync.fetchCollectionDates(uid: uid, daysBack: 90)
                dates = mergeCollectionDates(local: dates, remote: remoteDates)
                saveCollectionDates(dates)
            } catch {
                // Keep local dates as a deliberate fallback when remote read fails.
                analytics.error("streak_fetch_remote", message: error.localizedDescription, metadata: ["uid": uid])
                print("UserService streak fetch fallback to local for uid \(uid): \(error.localizedDescription)")
            }
        }

        let streak = Streak.calculateStreak(
            from: dates,
            now: now(),
            calendar: calendar
        )
        let formatter = ISO8601DateFormatter()

        return StreakResponse(
            currentStreak: streak.currentStreak,
            longestStreak: streak.longestStreak,
            lastCollectionDate: streak.lastCollectionDate.map { formatter.string(from: $0) },
            totalCollections: streak.totalCollections
        )
    }

    func getTotalChallengesCompleted() -> Int {
        userDefaults.integer(forKey: scopedKey(totalChallengesCompletedKeyBase))
    }

    func getChallengeCompletionDates() -> [Date] {
        loadCollectionDates()
    }
    
    func pendingRemoteSyncCount() -> Int {
        let pendingDays = userDefaults.stringArray(forKey: scopedKey(pendingRemoteSyncDaysKeyBase)) ?? []
        return pendingDays.count
    }

    func logChallengeCompletion() async {
        var dates = loadCollectionDates()
        let today = calendar.startOfDay(for: now())

        // Only add one collection per day for streak purposes
        if !dates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            incrementLocalChallengeCount()
            dates.append(today)
            saveCollectionDates(dates)
            enqueuePendingRemoteSyncDay(today)
            appendCompletionEvent(today)
            analytics.track("challenge_completed_local", metadata: ["day": dayKey(for: today)])

            // Also save to Firestore if user is authenticated
            if let uid = authSession.currentUserId {
                await flushPendingRemoteSyncDays(uid: uid)
            }
        }
    }

    private func mergeCollectionDates(local: [Date], remote: [Date]) -> [Date] {
        var seen = Set<Date>()

        func normalized(_ date: Date) -> Date {
            calendar.startOfDay(for: date)
        }

        var merged: [Date] = []
        for date in local + remote {
            let day = normalized(date)
            if !seen.contains(day) {
                seen.insert(day)
                merged.append(day)
            }
        }

        return merged
    }

    // MARK: - Persistence

    private func loadCollectionDates() -> [Date] {
        guard let data = userDefaults.data(forKey: scopedKey(collectionDatesKeyBase)) else {
            return []
        }

        do {
            return try JSONDecoder().decode([Date].self, from: data)
        } catch {
            return []
        }
    }

    private func saveCollectionDates(_ dates: [Date]) {
        do {
            let data = try JSONEncoder().encode(dates)
            userDefaults.set(data, forKey: scopedKey(collectionDatesKeyBase))
        } catch {
            // Ignore encoding errors for now
        }
    }

    private func incrementLocalChallengeCount() {
        let key = scopedKey(totalChallengesCompletedKeyBase)
        let current = userDefaults.integer(forKey: key)
        userDefaults.set(current + 1, forKey: key)
    }

    private func enqueuePendingRemoteSyncDay(_ day: Date) {
        let dayKey = dayKey(for: day)
        let key = scopedKey(pendingRemoteSyncDaysKeyBase)
        var pendingDays = userDefaults.stringArray(forKey: key) ?? []
        guard !pendingDays.contains(dayKey) else { return }
        pendingDays.append(dayKey)
        userDefaults.set(pendingDays, forKey: key)
    }
    
    private func appendCompletionEvent(_ day: Date) {
        let dayKey = dayKey(for: day)
        let key = scopedKey(completionEventLogKeyBase)
        var events = userDefaults.stringArray(forKey: key) ?? []
        guard !events.contains(dayKey) else { return }
        events.append(dayKey)
        userDefaults.set(events, forKey: key)
    }

    private func flushPendingRemoteSyncDays(uid: String) async {
        let key = scopedKey(pendingRemoteSyncDaysKeyBase)
        let pendingDays = userDefaults.stringArray(forKey: key) ?? []
        guard !pendingDays.isEmpty else { return }

        var remainingDays: [String] = []
        for dayKey in pendingDays {
            guard let dayDate = dateFromDayKey(dayKey) else { continue }
            do {
                try await performWithRetry(operationName: "syncChallengeCompletionToFirestore") {
                    try await self.remoteSync.syncChallengeCompletion(date: dayDate, uid: uid)
                }
                analytics.track("challenge_sync_remote_success", metadata: ["day": dayKey])
            } catch {
                remainingDays.append(dayKey)
                analytics.error(
                    "challenge_sync_remote_failed",
                    message: error.localizedDescription,
                    metadata: ["day": dayKey, "uid": uid]
                )
                // Stop here to preserve ordering and retry later.
                if let currentIndex = pendingDays.firstIndex(of: dayKey),
                   currentIndex + 1 < pendingDays.count {
                    remainingDays.append(contentsOf: pendingDays[(currentIndex + 1)...])
                }
                break
            }
        }

        userDefaults.set(remainingDays, forKey: key)
    }

    private func performWithRetry(
        operationName: String,
        retries: Int = 2,
        operation: () async throws -> Void
    ) async throws {
        var lastError: Error?

        for attempt in 0...retries {
            do {
                try await operation()
                return
            } catch {
                lastError = error
                let isLastAttempt = attempt == retries
                if isLastAttempt { break }

                let backoff = retryInitialDelayNanos * UInt64(1 << attempt)
                analytics.track(
                    "remote_retry",
                    metadata: [
                        "operation": operationName,
                        "attempt": "\(attempt + 2)"
                    ]
                )
                print("Retrying \(operationName), attempt \(attempt + 2)/\(retries + 1): \(error.localizedDescription)")
                try? await Task.sleep(nanoseconds: backoff)
            }
        }

        throw lastError ?? NSError(
            domain: "UserService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unknown retry failure in \(operationName)"]
        )
    }

    private func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func dateFromDayKey(_ dayKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey)
    }

    private var storageUserScope: String {
        authSession.currentUserId ?? "guest"
    }

    private func scopedKey(_ base: String) -> String {
        "\(base).\(storageUserScope)"
    }
}
