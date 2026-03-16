import Foundation

struct OnboardingResponse: Codable {
    var name: String
    var workoutLevel: WorkoutLevel?
    var maxStrength: MaxStrength
    var focusAreas: [String]
    var confidenceLevel: ConfidenceLevel
    var socialGoals: [SocialGoal]
    var notificationEnabled: Bool
    var completedAt: Date
    
    init(name: String = "",
         workoutLevel: WorkoutLevel? = nil,
         maxStrength: MaxStrength = .zero,
         focusAreas: [String] = [],
         confidenceLevel: ConfidenceLevel = .somewhatAnxious,
         socialGoals: [SocialGoal] = [],
         notificationEnabled: Bool = true,
         completedAt: Date = Date()) {
        self.name = name
        self.workoutLevel = workoutLevel
        self.maxStrength = maxStrength
        self.focusAreas = focusAreas
        self.confidenceLevel = confidenceLevel
        self.socialGoals = socialGoals
        self.notificationEnabled = notificationEnabled
        self.completedAt = completedAt
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case workoutLevel
        case maxStrength
        case focusAreas
        case confidenceLevel
        case socialGoals
        case notificationEnabled
        case completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        workoutLevel = try container.decodeIfPresent(WorkoutLevel.self, forKey: .workoutLevel)
        maxStrength = try container.decodeIfPresent(MaxStrength.self, forKey: .maxStrength) ?? .zero
        focusAreas = try container.decodeIfPresent([String].self, forKey: .focusAreas) ?? []
        confidenceLevel = try container.decodeIfPresent(ConfidenceLevel.self, forKey: .confidenceLevel) ?? .somewhatAnxious
        socialGoals = try container.decodeIfPresent([SocialGoal].self, forKey: .socialGoals) ?? []
        notificationEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationEnabled) ?? true
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(workoutLevel, forKey: .workoutLevel)
        try container.encode(maxStrength, forKey: .maxStrength)
        try container.encode(focusAreas, forKey: .focusAreas)
        try container.encode(confidenceLevel, forKey: .confidenceLevel)
        try container.encode(socialGoals, forKey: .socialGoals)
        try container.encode(notificationEnabled, forKey: .notificationEnabled)
        try container.encode(completedAt, forKey: .completedAt)
    }
}
