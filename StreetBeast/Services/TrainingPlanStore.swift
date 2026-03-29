import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class TrainingPlanStore: ObservableObject {
    static let shared = TrainingPlanStore()

    @Published private(set) var customPlans: [TrainingPlan] = []

    private let storageKeyBase = "training_plans_custom_v1"
    private let legacyStorageKey = "training_plans_custom"
    private let userDefaults: UserDefaults
    private let authSession: AuthSessionProviding
    private let db: Firestore?
    private var currentScope: String

    init(
        userDefaults: UserDefaults = .standard,
        authSession: AuthSessionProviding = FirebaseAuthSessionProvider(),
        db: Firestore? = Firestore.firestore()
    ) {
        self.userDefaults = userDefaults
        self.authSession = authSession
        self.db = db
        self.currentScope = authSession.currentUserId ?? "guest"
        load()
    }

    func updateUserScope(_ uid: String?) {
        let scope = uid ?? "guest"
        guard scope != currentScope else { return }
        currentScope = scope
        load()
    }

    func save(plan: TrainingPlan) {
        let normalized = plan.normalized()
        if let index = customPlans.firstIndex(where: { $0.id == normalized.id }) {
            customPlans[index] = normalized
        } else {
            customPlans.append(normalized)
        }
        customPlans = sortPlans(customPlans)
        persist()

        if let uid = authSession.currentUserId {
            Task {
                await syncPlan(normalized, uid: uid)
            }
        }
    }

    func delete(plan: TrainingPlan) {
        customPlans.removeAll { $0.id == plan.id }
        persist()

        if let uid = authSession.currentUserId {
            Task {
                await deleteRemotePlan(plan, uid: uid)
            }
        }
    }

    private func load() {
        if let data = userDefaults.data(forKey: scopedKey(storageKeyBase)),
           let decoded = try? JSONDecoder().decode([TrainingPlan].self, from: data) {
            customPlans = sortPlans(decoded)
            return
        }

        if let legacyData = userDefaults.data(forKey: legacyStorageKey),
           let decoded = try? JSONDecoder().decode([TrainingPlan].self, from: legacyData) {
            customPlans = sortPlans(decoded)
            persist()
            return
        }

        customPlans = []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(customPlans) else { return }
        userDefaults.set(data, forKey: scopedKey(storageKeyBase))
    }

    func refreshFromRemote(uid: String) async {
        guard let db else { return }
        do {
            let snapshot = try await db.collection("users")
                .document(uid)
                .collection("training_plans")
                .getDocuments()
            let remotePlans = snapshot.documents.compactMap { doc -> TrainingPlan? in
                TrainingPlan.fromDictionary(doc.data())
            }
            let merged = merge(local: customPlans, remote: remotePlans)
            customPlans = sortPlans(merged)
            persist()
        } catch {
            // Keep local data if remote fetch fails.
        }
    }

    private func merge(local: [TrainingPlan], remote: [TrainingPlan]) -> [TrainingPlan] {
        var map: [UUID: TrainingPlan] = [:]
        for plan in remote {
            map[plan.id] = plan
        }
        for plan in local {
            map[plan.id] = plan
        }
        return Array(map.values)
    }

    private func sortPlans(_ plans: [TrainingPlan]) -> [TrainingPlan] {
        plans.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func syncPlan(_ plan: TrainingPlan, uid: String) async {
        guard let db else { return }
        do {
            try await db.collection("users")
                .document(uid)
                .collection("training_plans")
                .document(plan.id.uuidString)
                .setData(planPayload(plan), merge: true)
        } catch {
            // Best-effort sync; keep local.
        }
    }

    private func deleteRemotePlan(_ plan: TrainingPlan, uid: String) async {
        guard let db else { return }
        do {
            try await db.collection("users")
                .document(uid)
                .collection("training_plans")
                .document(plan.id.uuidString)
                .delete()
        } catch {
            // Best-effort sync; keep local.
        }
    }

    private func planPayload(_ plan: TrainingPlan) -> [String: Any] {
        var data = plan.toDictionary()
        data["updatedAt"] = Timestamp(date: Date())
        return data
    }

    private func scopedKey(_ base: String) -> String {
        "\(base)_\(currentScope)"
    }
}
