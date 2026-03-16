import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Public API
    
    func register(email: String, password: String, name: String?) async throws -> AuthResponse {
        let authResult = try await createUser(withEmail: email, password: password)
        
        if let name = name {
            try await updateDisplayName(name, for: authResult.user)
        }
        
        let user = User(
            id: authResult.user.uid,
            email: authResult.user.email ?? email,
            name: authResult.user.displayName ?? name,
            createdAt: Date(),
            onboardingCompleted: false
        )
        
        // Create user document in Firestore
        try await createUserDocument(user)
        
        // We keep the existing AuthResponse shape but use the Firebase UID as a pseudo-token.
        return AuthResponse(user: user, token: authResult.user.uid)
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let authResult = try await signIn(withEmail: email, password: password)
        
        // Load user document from Firestore
        let user = try await fetchUserDocument(uid: authResult.user.uid) ?? User(
            id: authResult.user.uid,
            email: authResult.user.email ?? email,
            name: authResult.user.displayName,
            createdAt: Date(),
            onboardingCompleted: false
        )
        
        return AuthResponse(user: user, token: authResult.user.uid)
    }
    
    func signInAnonymously() async throws -> AuthResponse {
        let authResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown anonymous auth error"]))
                }
            }
        }
        
        let user = User(
            id: authResult.user.uid,
            email: "",
            name: "Guest",
            createdAt: Date(),
            onboardingCompleted: false
        )
        
        return AuthResponse(user: user, token: authResult.user.uid)
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            // Ignore sign-out errors for now; user will be treated as logged out on next check.
        }
    }
    
    var isAuthenticated: Bool {
        Auth.auth().currentUser != nil
    }
    
    // MARK: - Private helpers
    
    private func createUser(withEmail email: String, password: String) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown registration error"]))
                }
            }
        }
    }
    
    private func signIn(withEmail email: String, password: String) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown login error"]))
                }
            }
        }
    }
    
    private func updateDisplayName(_ name: String, for user: FirebaseAuth.User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.commitChanges { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Firestore helpers
    
    private func createUserDocument(_ user: User) async throws {
        let userRef = db.collection("users").document(user.id)
        var data: [String: Any] = [
            "id": user.id,
            "email": user.email,
            "name": user.name as Any,
            "createdAt": Timestamp(date: user.createdAt),
            "onboardingCompleted": user.onboardingCompleted,
            "totalChallengesCompleted": user.totalChallengesCompleted,
            // Temporary mirrored field for backward compatibility with legacy clients.
            "totalVersesCollected": user.totalChallengesCompleted
        ]
        if let lastCompleted = user.lastChallengeCompletedAt {
            data["lastChallengeCompletedAt"] = Timestamp(date: lastCompleted)
            // Temporary mirrored field for backward compatibility with legacy clients.
            data["lastVerseCollectedAt"] = Timestamp(date: lastCompleted)
        }
        try await userRef.setData(data)
    }
    
    func fetchUserDocument(uid: String) async throws -> User? {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        
        let timestamp = data["createdAt"] as? Timestamp
        let lastCollectedAt = (data["lastChallengeCompletedAt"] as? Timestamp) ?? (data["lastVerseCollectedAt"] as? Timestamp)
        let totalCompleted = (data["totalChallengesCompleted"] as? Int) ?? (data["totalVersesCollected"] as? Int) ?? 0
        let email = (data["email"] as? String) ?? (Auth.auth().currentUser?.email ?? "")
        let rawName = data["name"] as? String
        let resolvedName = resolveDisplayName(rawName: rawName, email: email)
        
        return User(
            id: data["id"] as? String ?? uid,
            email: email,
            name: resolvedName,
            createdAt: timestamp?.dateValue() ?? Date(),
            onboardingCompleted: data["onboardingCompleted"] as? Bool ?? false,
            totalChallengesCompleted: totalCompleted,
            lastChallengeCompletedAt: lastCollectedAt?.dateValue()
        )
    }
    
    func updateUserOnboarding(uid: String, completed: Bool) async throws {
        try await db.collection("users").document(uid).updateData([
            "onboardingCompleted": completed
        ])
    }
    
    func saveOnboardingData(_ data: OnboardingResponse, for uid: String) async throws {
        let onboardingRef = db.collection("users").document(uid).collection("onboarding").document("data")
        var payload: [String: Any] = [
            "name": data.name,
            "maxStrength": [
                "pullUps": data.maxStrength.pullUps,
                "pushUps": data.maxStrength.pushUps,
                "dips": data.maxStrength.dips,
                "muscleUps": data.maxStrength.muscleUps
            ],
            "focusAreas": data.focusAreas,
            "confidenceLevel": data.confidenceLevel.rawValue,
            "socialGoals": data.socialGoals.map { $0.rawValue },
            "notificationEnabled": data.notificationEnabled,
            "completedAt": Timestamp(date: data.completedAt)
        ]

        if let workoutLevel = data.workoutLevel?.rawValue {
            payload["workoutLevel"] = workoutLevel
        }

        try await onboardingRef.setData(payload)
        
        // Also update user document
        try await updateUserOnboarding(uid: uid, completed: true)
    }

    func updateMaxStrength(_ strength: MaxStrength, for uid: String) async throws {
        let onboardingRef = db.collection("users").document(uid).collection("onboarding").document("data")
        let payload: [String: Any] = [
            "maxStrength": [
                "pullUps": strength.pullUps,
                "pushUps": strength.pushUps,
                "dips": strength.dips,
                "muscleUps": strength.muscleUps
            ],
            "updatedAt": Timestamp(date: Date())
        ]
        try await onboardingRef.setData(payload, merge: true)
    }

    func fetchMaxStrength(uid: String) async throws -> MaxStrength? {
        let doc = try await db.collection("users").document(uid).collection("onboarding").document("data").getDocument()
        guard doc.exists, let data = doc.data(),
              let maxStrength = data["maxStrength"] as? [String: Any] else { return nil }

        let pullUps = maxStrength["pullUps"] as? Int ?? 0
        let pushUps = maxStrength["pushUps"] as? Int ?? 0
        let dips = maxStrength["dips"] as? Int ?? 0
        let muscleUps = maxStrength["muscleUps"] as? Int ?? 0

        return MaxStrength(pullUps: pullUps, pushUps: pushUps, dips: dips, muscleUps: muscleUps)
    }

    private func resolveDisplayName(rawName: String?, email: String) -> String? {
        let trimmedStoredName = rawName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedStoredName, !trimmedStoredName.isEmpty {
            return trimmedStoredName
        }

        let authName = Auth.auth().currentUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let authName, !authName.isEmpty {
            return authName
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return nil }
        let local = trimmedEmail.split(separator: "@").first.map(String.init) ?? trimmedEmail
        let cleaned = local.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
