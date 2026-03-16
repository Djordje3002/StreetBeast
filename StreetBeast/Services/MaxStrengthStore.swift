import Foundation
import Combine

@MainActor
final class MaxStrengthStore: ObservableObject {
    static let shared = MaxStrengthStore()

    @Published var current: MaxStrength {
        didSet { persist() }
    }

    private let storageKeyBase = "max_strength_current_v2"
    private let legacyStorageKey = "max_strength_current_v1"
    private let userDefaults: UserDefaults
    private let authSession: AuthSessionProviding
    private var currentScope: String

    init(
        userDefaults: UserDefaults = .standard,
        authSession: AuthSessionProviding? = nil
    ) {
        self.userDefaults = userDefaults
        let provider = authSession ?? FirebaseAuthSessionProvider()
        self.authSession = provider
        self.currentScope = provider.currentUserId ?? "guest"
        self.current = .zero
        load()
    }

    func updateUserScope(_ uid: String?) {
        let scope = uid ?? "guest"
        guard scope != currentScope else { return }
        currentScope = scope
        load()
    }

    func update(_ value: MaxStrength) {
        current = value
    }

    private func load() {
        if let data = userDefaults.data(forKey: scopedKey(storageKeyBase)),
           let decoded = try? JSONDecoder().decode(MaxStrength.self, from: data) {
            current = decoded
            return
        }

        if let legacyData = userDefaults.data(forKey: legacyStorageKey),
           let decoded = try? JSONDecoder().decode(MaxStrength.self, from: legacyData) {
            current = decoded
            persist()
            return
        }

        current = .zero
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(current) else { return }
        userDefaults.set(data, forKey: scopedKey(storageKeyBase))
    }

    private func scopedKey(_ base: String) -> String {
        "\(base)_\(currentScope)"
    }
}
