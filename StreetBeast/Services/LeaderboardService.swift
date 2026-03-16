import Foundation
import FirebaseFirestore
import Combine
import FirebaseAuth

struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let name: String
    let socialWins: Int
    let initials: String
    let isCurrentUser: Bool
}

class LeaderboardService: ObservableObject {
    static let shared = LeaderboardService()
    private let db = Firestore.firestore()
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "leaderboard.entries.cache.v1"
    private let fetchLimit = 50
    private let demoEntries: [LeaderboardEntry] = [
        LeaderboardEntry(id: "demo_1", name: "Marko", socialWins: 32, initials: "MA", isCurrentUser: false),
        LeaderboardEntry(id: "demo_2", name: "Stefan", socialWins: 29, initials: "ST", isCurrentUser: false),
        LeaderboardEntry(id: "demo_3", name: "Djordje", socialWins: 26, initials: "DJ", isCurrentUser: false),
        LeaderboardEntry(id: "demo_4", name: "Luka", socialWins: 24, initials: "LU", isCurrentUser: false),
        LeaderboardEntry(id: "demo_5", name: "Nikola", socialWins: 21, initials: "NI", isCurrentUser: false),
        LeaderboardEntry(id: "demo_6", name: "Ana", socialWins: 19, initials: "AN", isCurrentUser: false),
        LeaderboardEntry(id: "demo_7", name: "Mia", socialWins: 17, initials: "MI", isCurrentUser: false),
        LeaderboardEntry(id: "demo_8", name: "Sara", socialWins: 15, initials: "SA", isCurrentUser: false),
        LeaderboardEntry(id: "demo_9", name: "Teodora", socialWins: 13, initials: "TE", isCurrentUser: false),
        LeaderboardEntry(id: "demo_10", name: "Jovana", socialWins: 11, initials: "JO", isCurrentUser: false)
    ]

    @Published var topEntries: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private init() {
        topEntries = entriesWithDemoUsers(loadCachedEntries())
    }
    
    func fetchLeaderboard() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let documents = try await fetchLeaderboardDocumentsWithFallback()
            let currentUid = Auth.auth().currentUser?.uid
            let entries = buildEntries(from: documents, currentUid: currentUid)

            await MainActor.run {
                self.topEntries = entries
                self.isLoading = false
                self.error = nil
                self.storeCachedEntries(entries)
            }
        } catch {
            let cached = loadCachedEntries()
            await MainActor.run {
                self.error = error
                self.topEntries = self.entriesWithDemoUsers(cached)
                self.isLoading = false
            }
        }
    }

    private func fetchLeaderboardDocumentsWithFallback() async throws -> [QueryDocumentSnapshot] {
        do {
            let primarySnapshot = try await db.collection("users")
                .whereField("onboardingCompleted", isEqualTo: true)
                .order(by: "totalChallengesCompleted", descending: true)
                .limit(to: fetchLimit)
                .getDocuments()
            return primarySnapshot.documents
        } catch {
            guard shouldFallbackToOrderOnlyQuery(for: error) else {
                throw error
            }

            let fallbackSnapshot = try await db.collection("users")
                .order(by: "totalChallengesCompleted", descending: true)
                .limit(to: fetchLimit * 2)
                .getDocuments()

            let filtered = fallbackSnapshot.documents.filter { shouldIncludeInLeaderboard($0.data()) }
            return Array(filtered.prefix(fetchLimit))
        }
    }

    private func buildEntries(from documents: [QueryDocumentSnapshot], currentUid: String?) -> [LeaderboardEntry] {
        let mapped: [LeaderboardEntry] = documents.compactMap { doc in
            let data = doc.data()
            guard shouldIncludeInLeaderboard(data) else { return nil }
            let resolvedName = resolvedName(from: data["name"], fallbackDocId: doc.documentID)
            let total = intValue(from: data["totalChallengesCompleted"])
                ?? intValue(from: data["totalVersesCollected"])
                ?? 0

            return LeaderboardEntry(
                id: doc.documentID,
                name: resolvedName,
                socialWins: total,
                initials: initials(from: resolvedName),
                isCurrentUser: doc.documentID == currentUid
            )
        }

        let realEntries = mapped
            .sorted {
                if $0.socialWins == $1.socialWins {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.socialWins > $1.socialWins
            }

        return entriesWithDemoUsers(realEntries)
            .prefix(fetchLimit)
            .map { $0 }
    }

    private func entriesWithDemoUsers(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        var merged = entries
        let existingIds = Set(entries.map(\.id))

        for demo in demoEntries where !existingIds.contains(demo.id) {
            merged.append(demo)
        }

        return merged.sorted {
            if $0.socialWins == $1.socialWins {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.socialWins > $1.socialWins
        }
    }

    private func shouldFallbackToOrderOnlyQuery(for error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == FirestoreErrorDomain else { return false }
        // Firestore uses gRPC status codes in NSError.code for query failures.
        // 9 = failedPrecondition (e.g. missing composite index), 3 = invalidArgument.
        return nsError.code == 9 || nsError.code == 3
    }

    private func shouldIncludeInLeaderboard(_ data: [String: Any]) -> Bool {
        if let onboardingCompleted = data["onboardingCompleted"] as? Bool {
            return onboardingCompleted
        }
        return true
    }

    private func resolvedName(from value: Any?, fallbackDocId: String) -> String {
        let trimmed = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty {
            return trimmed
        }
        let suffix = String(fallbackDocId.suffix(4)).uppercased()
        return "User \(suffix)"
    }

    private func storeCachedEntries(_ entries: [LeaderboardEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        userDefaults.set(data, forKey: cacheKey)
    }

    private func loadCachedEntries() -> [LeaderboardEntry] {
        guard let data = userDefaults.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    private func initials(from name: String) -> String {
        let components = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func intValue(from any: Any?) -> Int? {
        switch any {
        case let value as Int:
            return value
        case let value as Int64:
            return Int(value)
        case let value as Double:
            return Int(value)
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }
}
