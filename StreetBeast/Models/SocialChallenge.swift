import Foundation
import SwiftUI

enum Zone: String, Codable, CaseIterable {
    case comfort
    case fear
    case learning
    case growth

    var color: Color {
        switch self {
        case .comfort: return .green
        case .fear: return .yellow
        case .learning: return .blue
        case .growth: return .purple
        }
    }
}

enum QuestionType: String, Codable {
    case scale
    case multipleChoice
    case text
    case yesNo
}

struct ChallengeQuestion: Codable, Identifiable {
    let id: String
    let textEn: String
    let textSr: String
    let type: QuestionType
    let options: [String]?
    let optionsSr: [String]?
    let isPreChallenge: Bool

    func text(for language: Language) -> String {
        language == .serbian ? textSr : textEn
    }

    func localizedOptions(for language: Language) -> [String]? {
        language == .serbian ? optionsSr : options
    }
}

struct ChallengeFeedback: Codable {
    let questionId: String
    let answerKey: String
    let feedbackEn: String
    let feedbackSr: String

    func feedback(for language: Language) -> String {
        language == .serbian ? feedbackSr : feedbackEn
    }
}

struct SocialChallenge: Identifiable, Codable {
    let id: String
    let titleEn: String
    let titleSr: String
    let descriptionEn: String
    let descriptionSr: String
    let difficultyLevel: Int
    let zone: Zone
    let questions: [ChallengeQuestion]
    let feedbackTemplates: [ChallengeFeedback]
    var isCompleted: Bool = false

    func title(for language: Language) -> String {
        language == .serbian ? titleSr : titleEn
    }

    func description(for language: Language) -> String {
        language == .serbian ? descriptionSr : descriptionEn
    }

    // Minimal offline fallback pack.
    // Full challenge catalog should be served from backend content.
    static var initialChallenges: [SocialChallenge] {
        [
            SocialChallenge(
                id: "SB_1",
                titleEn: "Beginner Workout",
                titleSr: "Pocetni trening",
                descriptionEn: "5 rounds: 10 pull-ups, 20 pushups, 15 dips, 30 squats.",
                descriptionSr: "5 rundi: 10 zgibova, 20 sklekova, 15 propadanja, 30 cucnjeva.",
                difficultyLevel: 1,
                zone: .comfort,
                questions: [],
                feedbackTemplates: []
            ),
            SocialChallenge(
                id: "SB_2",
                titleEn: "Strength Builder",
                titleSr: "Trening snage",
                descriptionEn: "5 rounds: 6 pull-ups, 12 pushups, 10 dips, 6 muscle-ups.",
                descriptionSr: "5 rundi: 6 zgibova, 12 sklekova, 10 propadanja, 6 muscle-upova.",
                difficultyLevel: 3,
                zone: .learning,
                questions: [],
                feedbackTemplates: []
            ),
            SocialChallenge(
                id: "SB_3",
                titleEn: "Endurance Circuit",
                titleSr: "Kondicioni krug",
                descriptionEn: "6 rounds: 12 pull-ups, 25 pushups, 20 dips, 40 squats.",
                descriptionSr: "6 rundi: 12 zgibova, 25 sklekova, 20 propadanja, 40 cucnjeva.",
                difficultyLevel: 2,
                zone: .learning,
                questions: [],
                feedbackTemplates: []
            ),
            SocialChallenge(
                id: "SB_4",
                titleEn: "Custom Workout",
                titleSr: "Prilagodjeni trening",
                descriptionEn: "Build your own routine with custom rounds, reps, and rest.",
                descriptionSr: "Napravi sopstvenu rutinu sa prilagodjenim rundama, ponavljanjima i odmorom.",
                difficultyLevel: 1,
                zone: .growth,
                questions: [],
                feedbackTemplates: []
            )
        ]
    }
}
