import Foundation
import FirebaseFirestore
import Combine

struct PublicProfileData {
    let id: String
    let name: String
    let socialWins: Int
    let initials: String
    let currentStreak: Int
    let longestStreak: Int
    let joinDate: Date?
}

class PublicProfileService: ObservableObject {
    @Published var profile: PublicProfileData?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private let calendar = Calendar.current
    private let now = Date()
    
    func fetchProfile(for userId: String, entryName: String, entryWins: Int, entryInitials: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // First try to fetch the user document to get joinDate and verify they exist
            let userDoc = try await db.collection("users").document(userId).getDocument()
            let joinDate = (userDoc.data()?["createdAt"] as? Timestamp)?.dateValue()
            
            // Now fetch their collections for the last 90 days to compute streak
            let cutoff = calendar.date(byAdding: .day, value: -90, to: now) ?? now
            let collectionsSnapshot = try await db.collection("users").document(userId)
                .collection("collections")
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: cutoff))
                .getDocuments()
                
            let dates = collectionsSnapshot.documents.compactMap { doc in
                (doc.data()["date"] as? Timestamp)?.dateValue()
            }
            
            let streak = Streak.calculateStreak(from: dates, now: Date(), calendar: calendar)
            
            let data = PublicProfileData(
                id: userId,
                name: entryName,
                socialWins: entryWins,
                initials: entryInitials,
                currentStreak: streak.currentStreak,
                longestStreak: streak.longestStreak,
                joinDate: joinDate
            )
            
            await MainActor.run {
                self.profile = data
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
}
