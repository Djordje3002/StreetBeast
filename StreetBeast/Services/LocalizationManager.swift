import Foundation
import SwiftUI
import Combine

enum Language: String, CaseIterable, Codable {
    case english = "en"
    case serbian = "sr"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .serbian: return "Srpski"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language = .english {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Default to English if no preference saved
            // Could strictly default to system language if we wanted, but English as default is safe
            self.currentLanguage = .serbian
        }
    }
    
    func localized(_ key: String) -> String {
        let bundle = localizedBundle(for: currentLanguage) ?? .main
        let localizedValue = bundle.localizedString(forKey: key, value: key, table: "Localizable")
        return localizedValue
    }

    func localizedPlural(_ key: String, count: Int) -> String {
        let bundle = localizedBundle(for: currentLanguage) ?? .main
        let format = bundle.localizedString(forKey: key, value: key, table: "Localizable")
        if format == key {
            // Fallback when plural resources are unavailable in the active bundle.
            return "\(count) \(localized("leaderboard_wins_label"))"
        }
        return String.localizedStringWithFormat(format, count)
    }

    private func localizedBundle(for language: Language) -> Bundle? {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }
}
