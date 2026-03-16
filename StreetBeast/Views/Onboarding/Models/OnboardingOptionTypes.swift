import Foundation

enum ConfidenceLevel: String, CaseIterable, Codable {
    case socialButterfly
    case comfortable
    case somewhatAnxious
    case veryAnxious

    var localizedTitle: String {
        switch self {
        case .socialButterfly:
            return LocalizationManager.shared.localized("onboarding_conf_level_butterfly")
        case .comfortable:
            return LocalizationManager.shared.localized("onboarding_conf_level_comfortable")
        case .somewhatAnxious:
            return LocalizationManager.shared.localized("onboarding_conf_level_anxious")
        case .veryAnxious:
            return LocalizationManager.shared.localized("onboarding_conf_level_very_anxious")
        }
    }
}

enum SocialGoal: String, CaseIterable, Codable {
    case makeNewFriends
    case overcomeAnxiety
    case publicSpeaking
    case datingConfidence
    case networking

    var localizedTitle: String {
        switch self {
        case .makeNewFriends:
            return LocalizationManager.shared.localized("onboarding_goal_friends")
        case .overcomeAnxiety:
            return LocalizationManager.shared.localized("onboarding_goal_anxiety")
        case .publicSpeaking:
            return LocalizationManager.shared.localized("onboarding_goal_speaking")
        case .datingConfidence:
            return LocalizationManager.shared.localized("onboarding_goal_dating")
        case .networking:
            return LocalizationManager.shared.localized("onboarding_goal_networking")
        }
    }
}

enum WorkoutLevel: String, CaseIterable, Codable {
    case beginner
    case intermediate
    case advanced

    var localizedTitle: String {
        switch self {
        case .beginner:
            return LocalizationManager.shared.localized("onboarding_level_beginner")
        case .intermediate:
            return LocalizationManager.shared.localized("onboarding_level_intermediate")
        case .advanced:
            return LocalizationManager.shared.localized("onboarding_level_advanced")
        }
    }
}
