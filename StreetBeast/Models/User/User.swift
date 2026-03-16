import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let createdAt: Date
    let onboardingCompleted: Bool
    let totalChallengesCompleted: Int
    let lastChallengeCompletedAt: Date?
    
    init(
        id: String = UUID().uuidString,
        email: String,
        name: String? = nil,
        createdAt: Date = Date(),
        onboardingCompleted: Bool = false,
        totalChallengesCompleted: Int = 0,
        lastChallengeCompletedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.onboardingCompleted = onboardingCompleted
        self.totalChallengesCompleted = totalChallengesCompleted
        self.lastChallengeCompletedAt = lastChallengeCompletedAt
    }
}

extension User {
    var normalizedName: String? {
        guard let name else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var emailLocalPart: String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return nil }
        let local = trimmedEmail.split(separator: "@").first.map(String.init) ?? trimmedEmail
        let cleaned = local.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    var preferredDisplayName: String? {
        normalizedName ?? emailLocalPart
    }
}
