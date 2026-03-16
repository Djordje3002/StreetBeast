import Foundation
import SwiftUI
import Combine
import FirebaseAuth

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var isAnonymous = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let authService = AuthService.shared
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var isSigningInAnonymously = false
    private let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    private var lastKnownStorageUserScope: String?
    
    private init() {
        guard !isRunningTests else { return }
        setupAuthStateListener()
        checkAuthentication()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                await self?.handleAuthStateChange(user: user)
            }
        }
    }
    
    @MainActor
    private func handleAuthStateChange(user: FirebaseAuth.User?) async {
        let currentScope = user?.uid ?? "guest"
        if currentScope != lastKnownStorageUserScope {
            lastKnownStorageUserScope = currentScope
            TrainingPlanStore.shared.updateUserScope(user?.uid)
            WorkoutSessionStore.shared.updateUserScope(user?.uid)
            MaxStrengthStore.shared.updateUserScope(user?.uid)
        }

        if let user = user {
            isAuthenticated = true
            isAnonymous = user.isAnonymous
            // Load user data from Firestore
            do {
                if let loadedUser = try await authService.fetchUserDocument(uid: user.uid) {
                    currentUser = loadedUser
                } else {
                    currentUser = User(
                        id: user.uid,
                        email: user.email ?? "",
                        name: user.displayName,
                        createdAt: Date(),
                        onboardingCompleted: false
                    )
                }
            } catch {
                // If Firestore fetch fails, create basic user from auth data
                currentUser = User(
                    id: user.uid,
                    email: user.email ?? "",
                    name: user.displayName,
                    createdAt: Date(),
                    onboardingCompleted: false
                )
            }
            
            _ = await OnboardingSyncService.shared.flushIfPossible(uid: user.uid)
            _ = await MaxStrengthSyncService.shared.flushIfPossible(uid: user.uid)
            await TrainingPlanStore.shared.refreshFromRemote(uid: user.uid)
            await WorkoutSessionStore.shared.refreshFromRemote(uid: user.uid)
            await WorkoutSessionStore.shared.flushPendingRemote(uid: user.uid)

            do {
                if let remoteStrength = try await authService.fetchMaxStrength(uid: user.uid) {
                    MaxStrengthStore.shared.update(remoteStrength)
                }
            } catch {
                // Keep local max strength if remote fetch fails.
            }
        } else {
            isAuthenticated = false
            isAnonymous = false
            currentUser = nil

            // Auto-sign in anonymously if no user is found
            ensureAnonymousSession()
        }
    }
    
    func checkAuthentication() {
        guard !isRunningTests else { return }
        isAuthenticated = authService.isAuthenticated
        if isAuthenticated, let user = Auth.auth().currentUser {
            Task {
                await handleAuthStateChange(user: user)
            }
        } else {
            // Sign in anonymously so we have a UID for Firestore
            ensureAnonymousSession()
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let response = try await authService.login(email: email, password: password)
            await MainActor.run {
                self.currentUser = response.user
                self.isAuthenticated = true
                self.isAnonymous = false
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func register(email: String, password: String, name: String?) async {
        isLoading = true
        error = nil
        
        do {
            let response = try await authService.register(email: email, password: password, name: name)
            await MainActor.run {
                self.currentUser = response.user
                self.isAuthenticated = true
                self.isAnonymous = false
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func logout() {
        authService.logout()
        currentUser = nil
        isAuthenticated = false
        isAnonymous = false
    }
    
    private func ensureAnonymousSession() {
        guard !isRunningTests else { return }
        guard !isSigningInAnonymously else { return }
        isSigningInAnonymously = true
        
        Task { @MainActor in
            defer { isSigningInAnonymously = false }
            do {
                _ = try await authService.signInAnonymously()
            } catch {
                print("Anonymous sign-in failed: \(error)")
            }
        }
    }
}
