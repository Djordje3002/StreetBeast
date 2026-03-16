import Foundation

struct WorkoutXP {
    static let xpPerMinute = 10
    static let minimumXP = 20

    static func xp(for session: WorkoutSession) -> Int {
        let totalSeconds = max(session.totalDurationSeconds, 0)
        guard totalSeconds > 0 else { return 0 }
        let minutes = Double(totalSeconds) / 60.0
        let raw = Int((minutes * Double(xpPerMinute)).rounded())
        return max(raw, minimumXP)
    }

    static func totalXP(for sessions: [WorkoutSession]) -> Int {
        sessions.reduce(0) { $0 + xp(for: $1) }
    }
}
