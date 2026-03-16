import Foundation

struct Streak: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let lastCollectionDate: Date?
    let totalCollections: Int
    
    init(currentStreak: Int = 0, longestStreak: Int = 0, lastCollectionDate: Date? = nil, totalCollections: Int = 0) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCollectionDate = lastCollectionDate
        self.totalCollections = totalCollections
    }
    
    static func calculateStreak(from collectionDates: [Date]) -> Streak {
        calculateStreak(from: collectionDates, now: Date(), calendar: .current)
    }

    static func calculateStreak(
        from collectionDates: [Date],
        now: Date,
        calendar: Calendar
    ) -> Streak {
        guard !collectionDates.isEmpty else {
            return Streak()
        }

        let today = calendar.startOfDay(for: now)
        let uniqueDays = Array(
            Set(collectionDates.map { calendar.startOfDay(for: $0) })
                .filter { $0 <= today }
        ).sorted(by: >)
        guard !uniqueDays.isEmpty else {
            return Streak()
        }
        
        guard let latestDay = uniqueDays.first else {
            return Streak()
        }
        
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        
        var currentStreak = 0
        if latestDay == today || latestDay == yesterday {
            currentStreak = 1
            for index in 1..<uniqueDays.count {
                let previous = uniqueDays[index - 1]
                let current = uniqueDays[index]
                let expected = calendar.date(byAdding: .day, value: -1, to: previous) ?? previous
                if current == expected {
                    currentStreak += 1
                } else {
                    break
                }
            }
        }
        
        var longestStreak = 1
        var tempStreak = 1
        if uniqueDays.count > 1 {
            for index in 1..<uniqueDays.count {
                let previous = uniqueDays[index - 1]
                let current = uniqueDays[index]
                let expected = calendar.date(byAdding: .day, value: -1, to: previous) ?? previous
                if current == expected {
                    tempStreak += 1
                } else {
                    tempStreak = 1
                }
                longestStreak = max(longestStreak, tempStreak)
            }
        }
        
        return Streak(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastCollectionDate: latestDay,
            totalCollections: uniqueDays.count
        )
    }
}
