import Foundation

struct XPLeveling {
    static let maxLevel = 10
    static let xpPerChallenge = 120
    static let baseXPIncrement = 300
    static let incrementGrowth: Double = 1.35

    struct LevelInfo: Equatable {
        let level: Int
        let progress: Double
        let currentLevelXP: Int
        let nextLevelXP: Int
    }

    static func totalXP(forChallenges completedChallenges: Int) -> Int {
        max(0, completedChallenges) * xpPerChallenge
    }

    static func xpForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }

        let targetLevel = min(level, maxLevel)
        var xp = 0
        var increment = baseXPIncrement

        for _ in 2...targetLevel {
            xp += increment
            increment = max(increment + 1, Int((Double(increment) * incrementGrowth).rounded(.up)))
        }

        return xp
    }

    static func levelInfo(totalXP: Int) -> LevelInfo {
        let clampedXP = max(0, totalXP)
        var resolvedLevel = 1

        if maxLevel >= 2 {
            for candidate in 2...maxLevel {
                if clampedXP >= xpForLevel(candidate) {
                    resolvedLevel = candidate
                } else {
                    break
                }
            }
        }

        let currentXP = xpForLevel(resolvedLevel)
        let nextXP = resolvedLevel == maxLevel ? currentXP : xpForLevel(resolvedLevel + 1)
        let span = max(nextXP - currentXP, 1)
        let rawProgress = resolvedLevel == maxLevel ? 1.0 : Double(clampedXP - currentXP) / Double(span)
        let progress = min(max(rawProgress, 0.0), 1.0)

        return LevelInfo(
            level: resolvedLevel,
            progress: progress,
            currentLevelXP: currentXP,
            nextLevelXP: nextXP
        )
    }
}
