import Foundation

protocol ChallengeServicing: AnyObject {
    func getDailyChallenge() async -> DailyChallengeResponse
    func completeChallenge(id: String)
    func isChallengeCompleted(id: String) -> Bool
}

protocol ChallengeCompletionLogging: AnyObject {
    func logChallengeCompletion() async
}

protocol UserServicing: AnyObject {
    func getStreak() async throws -> StreakResponse
    func getTotalChallengesCompleted() -> Int
    func pendingRemoteSyncCount() -> Int
    func getChallengeCompletionDates() -> [Date]
}
