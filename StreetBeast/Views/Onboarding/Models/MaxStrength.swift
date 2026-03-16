import Foundation

struct MaxStrength: Codable, Equatable {
    var pullUps: Int
    var pushUps: Int
    var dips: Int
    var muscleUps: Int

    static let zero = MaxStrength(pullUps: 0, pushUps: 0, dips: 0, muscleUps: 0)
}
