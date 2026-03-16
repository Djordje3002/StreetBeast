import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct ChallengeWidgetPayload: Codable {
    let id: String
    let titleEn: String
    let titleSr: String
    let descriptionEn: String
    let descriptionSr: String
    let dayKey: String
    let updatedAt: Date
}

enum ChallengeWidgetSync {
    static let appGroupIdentifier = "group.com.streetbeast.widget"
    static let payloadKey = "challenge_of_day_payload_v1"
    static let widgetKind = "ChallengeOfDayWidget"

    static func persist(challenge: SocialChallenge, date: Date, calendar: Calendar) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }

        let payload = ChallengeWidgetPayload(
            id: challenge.id,
            titleEn: challenge.titleEn,
            titleSr: challenge.titleSr,
            descriptionEn: challenge.descriptionEn,
            descriptionSr: challenge.descriptionSr,
            dayKey: dayKey(for: date, calendar: calendar),
            updatedAt: Date()
        )

        do {
            let encodedPayload = try JSONEncoder().encode(payload)
            sharedDefaults.set(encodedPayload, forKey: payloadKey)
#if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
#endif
        } catch {
            // Widget sync failures should never break core app behavior.
        }
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // Theme is now fixed, so no theme metadata is stored.
}
