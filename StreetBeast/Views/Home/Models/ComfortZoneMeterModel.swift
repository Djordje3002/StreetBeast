import Foundation

struct ComfortZoneMeterModel: Equatable {
    let yearlyScore: Double
    let monthScore: Double
    let weekScore: Double
    let dayScore: Double

    init(scoresByRange: [MeterRange: Double]) {
        let yearly = Self.clamp(scoresByRange[.year1Y] ?? scoresByRange[.custom] ?? 0)
        self.yearlyScore = yearly
        self.monthScore = Self.clamp(scoresByRange[.month1M] ?? scoresByRange[.month3M] ?? yearly)
        self.weekScore = Self.clamp(scoresByRange[.week7D] ?? scoresByRange[.month1M] ?? yearly)
        self.dayScore = Self.clamp(scoresByRange[.day24H] ?? scoresByRange[.week7D] ?? yearly)
    }

    var scorePercent: Int {
        Int((yearlyScore * 100).rounded())
    }

    var activeBand: ComfortZoneBand {
        ComfortZoneBand.band(for: yearlyScore)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

enum ComfortZoneBand: CaseIterable {
    case home
    case learning
    case grow

    static func band(for score: Double) -> ComfortZoneBand {
        if score < (1.0 / 3.0) { return .home }
        if score < (2.0 / 3.0) { return .learning }
        return .grow
    }

    var zoneKey: String {
        switch self {
        case .home:
            return "comfort_zone_zone_comfort"
        case .learning:
            return "comfort_zone_zone_learning"
        case .grow:
            return "comfort_zone_zone_growth"
        }
    }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .learning:
            return "Learning"
        case .grow:
            return "Grow"
        }
    }

    var symbol: String {
        switch self {
        case .home:
            return "house.fill"
        case .learning:
            return "book.fill"
        case .grow:
            return "arrow.up.right.circle.fill"
        }
    }

    var rangeText: String {
        switch self {
        case .home:
            return "0-33%"
        case .learning:
            return "34-66%"
        case .grow:
            return "67-100%"
        }
    }
}

enum MeterRange: String, CaseIterable {
    case day24H = "24H"
    case week7D = "7D"
    case month1M = "1M"
    case month3M = "3M"
    case year1Y = "1Y"
    case custom = "Custom"

    var lookbackDays: Int? {
        switch self {
        case .day24H:
            return 1
        case .week7D:
            return 7
        case .month1M:
            return 30
        case .month3M:
            return 90
        case .year1Y:
            return 365
        case .custom:
            return nil
        }
    }

    var challengeWeight: Double {
        switch self {
        case .day24H:
            return 10.0
        case .week7D:
            return 4.0
        case .month1M:
            return 2.0
        case .month3M:
            return 1.3
        case .year1Y, .custom:
            return 1.0
        }
    }

}
