import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class WorkoutSessionStore: ObservableObject {
    static let shared = WorkoutSessionStore()

    @Published private(set) var sessions: [WorkoutSession] = []

    private let storageKeyBase = "workout_sessions_v1"
    private let legacyStorageKey = "workout_sessions"
    private let pendingKeyBase = "workout_sessions_pending_v1"

    private let userDefaults: UserDefaults
    private let authSession: AuthSessionProviding
    private let db: Firestore?
    private let calendar: Calendar

    private var currentScope: String

    init(
        userDefaults: UserDefaults = .standard,
        authSession: AuthSessionProviding = FirebaseAuthSessionProvider(),
        db: Firestore? = Firestore.firestore(),
        calendar: Calendar = .current
    ) {
        self.userDefaults = userDefaults
        self.authSession = authSession
        self.db = db
        self.calendar = calendar
        self.currentScope = authSession.currentUserId ?? "guest"
        load()
    }

    var totalXP: Int {
        WorkoutXP.totalXP(for: sessions)
    }

    var levelInfo: XPLeveling.LevelInfo {
        XPLeveling.levelInfo(totalXP: totalXP)
    }

    func updateUserScope(_ uid: String?) {
        let scope = uid ?? "guest"
        guard scope != currentScope else { return }
        currentScope = scope
        load()
    }

    func record(_ session: WorkoutSession) {
        sessions.insert(session, at: 0)
        sessions.sort { $0.completedAt > $1.completedAt }
        persist()
        enqueuePending(id: session.id)

        guard let uid = authSession.currentUserId else { return }
        Task {
            await syncSession(session, uid: uid)
        }
    }

    func refreshFromRemote(uid: String) async {
        guard let db else { return }
        do {
            let snapshot = try await db.collection("users")
                .document(uid)
                .collection("workouts")
                .order(by: "completedAt", descending: true)
                .limit(to: 180)
                .getDocuments()

            let remoteSessions = snapshot.documents.compactMap { doc in
                decodeSession(from: doc.data(), fallbackId: doc.documentID)
            }

            let merged = merge(local: sessions, remote: remoteSessions)
            sessions = merged.sorted { $0.completedAt > $1.completedAt }
            persist()
        } catch {
            // Silent fail to keep local data available.
        }
    }

    func flushPendingRemote(uid: String) async {
        guard let db else { return }
        var pendingIds = pendingSessionIds()
        guard !pendingIds.isEmpty else { return }

        var remaining: [String] = []
        for id in pendingIds {
            guard let uuid = UUID(uuidString: id),
                  let session = sessions.first(where: { $0.id == uuid }) else {
                continue
            }

            do {
                try await db.collection("users")
                    .document(uid)
                    .collection("workouts")
                    .document(session.id.uuidString)
                    .setData(sessionPayload(session), merge: true)
            } catch {
                remaining.append(id)
            }
        }

        savePending(ids: remaining)
    }

    func weeklyXPSeries(weeks: Int) -> [Double] {
        weeklySeries(weeks: weeks).map { Double($0.xp) }
    }

    func weeklyVolumeSeries(weeks: Int) -> [Double] {
        weeklySeries(weeks: weeks).map { $0.volumeMinutes }
    }

    func totalWorkouts(weeks: Int) -> Int {
        weeklySeries(weeks: weeks).reduce(0) { $0 + $1.workouts }
    }

    // MARK: - Private

    private struct WeeklySummary {
        let start: Date
        var xp: Int
        var volumeMinutes: Double
        var workouts: Int
    }

    private func weeklySeries(weeks: Int) -> [WeeklySummary] {
        let clampedWeeks = max(weeks, 1)
        let now = Date()
        let currentStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)

        var buckets: [WeeklySummary] = []
        for offset in stride(from: clampedWeeks - 1, through: 0, by: -1) {
            let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: currentStart) ?? currentStart
            buckets.append(WeeklySummary(start: start, xp: 0, volumeMinutes: 0, workouts: 0))
        }

        let grouped = Dictionary(grouping: sessions) { session in
            calendar.dateInterval(of: .weekOfYear, for: session.completedAt)?.start ?? calendar.startOfDay(for: session.completedAt)
        }

        for index in buckets.indices {
            let start = buckets[index].start
            let weekSessions = grouped[start] ?? []
            let xp = weekSessions.reduce(0) { $0 + WorkoutXP.xp(for: $1) }
            let volumeMinutes = weekSessions.reduce(0.0) { total, session in
                let minutes = Double(max(session.workDurationSeconds, 0)) / 60.0
                return total + minutes
            }

            buckets[index].xp = xp
            buckets[index].volumeMinutes = volumeMinutes
            buckets[index].workouts = weekSessions.count
        }

        return buckets
    }

    private func merge(local: [WorkoutSession], remote: [WorkoutSession]) -> [WorkoutSession] {
        var map: [UUID: WorkoutSession] = [:]
        for session in remote {
            map[session.id] = session
        }
        for session in local {
            map[session.id] = session
        }
        return Array(map.values)
    }

    private func pendingSessionIds() -> [String] {
        userDefaults.stringArray(forKey: scopedKey(pendingKeyBase)) ?? []
    }

    private func enqueuePending(id: UUID) {
        var pending = pendingSessionIds()
        let rawId = id.uuidString
        if !pending.contains(rawId) {
            pending.append(rawId)
            savePending(ids: pending)
        }
    }

    private func removePending(id: UUID) {
        var pending = pendingSessionIds()
        let rawId = id.uuidString
        guard pending.contains(rawId) else { return }
        pending.removeAll { $0 == rawId }
        savePending(ids: pending)
    }

    private func savePending(ids: [String]) {
        userDefaults.set(ids, forKey: scopedKey(pendingKeyBase))
    }

    private func load() {
        if let data = userDefaults.data(forKey: scopedKey(storageKeyBase)),
           let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            sessions = decoded.sorted { $0.completedAt > $1.completedAt }
            return
        }

        if let legacyData = userDefaults.data(forKey: legacyStorageKey),
           let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: legacyData) {
            sessions = decoded.sorted { $0.completedAt > $1.completedAt }
            persist()
            return
        }

        sessions = []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        userDefaults.set(data, forKey: scopedKey(storageKeyBase))
    }

    private func scopedKey(_ base: String) -> String {
        "\(base)_\(currentScope)"
    }

    private func syncSession(_ session: WorkoutSession, uid: String) async {
        guard let db else { return }
        do {
            try await db.collection("users")
                .document(uid)
                .collection("workouts")
                .document(session.id.uuidString)
                .setData(sessionPayload(session), merge: true)
            removePending(id: session.id)
        } catch {
            enqueuePending(id: session.id)
        }
    }

    private func sessionPayload(_ session: WorkoutSession) -> [String: Any] {
        var data: [String: Any] = [
            "id": session.id.uuidString,
            "startedAt": Timestamp(date: session.startedAt),
            "completedAt": Timestamp(date: session.completedAt),
            "totalDurationSeconds": session.totalDurationSeconds,
            "workDurationSeconds": session.workDurationSeconds,
            "restDurationSeconds": session.restDurationSeconds,
            "totalSteps": session.totalSteps,
            "workSteps": session.workSteps,
            "restSteps": session.restSteps,
            "planId": session.plan.id.uuidString,
            "planName": session.plan.name,
            "plan": session.plan.toDictionary()
        ]

        if let nameKey = session.plan.nameKey {
            data["planNameKey"] = nameKey
        }

        return data
    }

    private func decodeSession(from data: [String: Any], fallbackId: String) -> WorkoutSession? {
        let idString = data["id"] as? String ?? fallbackId
        let id = UUID(uuidString: idString) ?? UUID()

        let startedAt = (data["startedAt"] as? Timestamp)?.dateValue()
            ?? (data["startedAt"] as? Date) ?? Date()
        let completedAt = (data["completedAt"] as? Timestamp)?.dateValue()
            ?? (data["completedAt"] as? Date) ?? startedAt

        if let planData = data["plan"] as? [String: Any],
           let plan = TrainingPlan.fromDictionary(planData) {
            var session = WorkoutSession(id: id, plan: plan, startedAt: startedAt, completedAt: completedAt)
            session.totalDurationSeconds = intValue(from: data["totalDurationSeconds"]) ?? session.totalDurationSeconds
            session.workDurationSeconds = intValue(from: data["workDurationSeconds"]) ?? session.workDurationSeconds
            session.restDurationSeconds = intValue(from: data["restDurationSeconds"]) ?? session.restDurationSeconds
            session.totalSteps = intValue(from: data["totalSteps"]) ?? session.totalSteps
            session.workSteps = intValue(from: data["workSteps"]) ?? session.workSteps
            session.restSteps = intValue(from: data["restSteps"]) ?? session.restSteps
            return session
        }

        let planName = data["planName"] as? String ?? "Workout"
        let planNameKey = data["planNameKey"] as? String
        let planIdString = data["planId"] as? String ?? UUID().uuidString
        let planId = UUID(uuidString: planIdString) ?? UUID()
        let fallbackPlan = TrainingPlan(id: planId, name: planName, nameKey: planNameKey, prepareSeconds: 0, steps: [])
        var session = WorkoutSession(id: id, plan: fallbackPlan, startedAt: startedAt, completedAt: completedAt)
        session.totalDurationSeconds = intValue(from: data["totalDurationSeconds"]) ?? session.totalDurationSeconds
        session.workDurationSeconds = intValue(from: data["workDurationSeconds"]) ?? session.workDurationSeconds
        session.restDurationSeconds = intValue(from: data["restDurationSeconds"]) ?? session.restDurationSeconds
        session.totalSteps = intValue(from: data["totalSteps"]) ?? session.totalSteps
        session.workSteps = intValue(from: data["workSteps"]) ?? session.workSteps
        session.restSteps = intValue(from: data["restSteps"]) ?? session.restSteps
        return session
    }

    private func intValue(from value: Any?) -> Int? {
        if let intValue = value as? Int { return intValue }
        if let int64Value = value as? Int64 { return Int(int64Value) }
        if let doubleValue = value as? Double { return Int(doubleValue) }
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }
}
