//
//  StreetBeastApp.swift
//  StreetBeast
//
//  Created by Djordje on 3. 12. 2025..
//

import SwiftUI
import FirebaseCore

@main
struct StreetBeastApp: App {
    @StateObject private var authManager: AuthManager
    @StateObject private var designSystem: DesignSystem
    @StateObject private var toastManager: ToastManager

    private let isRunningTests: Bool
    
    init() {
        isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        _authManager = StateObject(wrappedValue: AuthManager.shared)
        _designSystem = StateObject(wrappedValue: DesignSystem.shared)
        _toastManager = StateObject(wrappedValue: ToastManager.shared)

        AppStorageMigrationService.shared.runMigrationsIfNeeded()

        if !isRunningTests {
            NotificationService.shared.configure()
            Task {
                _ = await AppContentService.shared.refreshFromBackendIfNeeded()
            }
        }
        
        #if DEBUG
        if !isRunningTests {
            // Always start from scratch in local debug runs to exercise full app flow.
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            AuthManager.shared.logout()
        }
        #endif

        _hasCompletedOnboarding = State(initialValue: UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))
    }

    @State private var hasCompletedOnboarding: Bool
    @State private var onboardingData: OnboardingResponse?
    @State private var isSplashScreenShowing = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isSplashScreenShowing {
                    SplashScreenView {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)) {
                            isSplashScreenShowing = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    mainContent
                }
            }
            .environmentObject(authManager)
            .environmentObject(designSystem)
            .environmentObject(toastManager)
            .toast()
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if !hasCompletedOnboarding {
            OnboardingView { data in
                onboardingData = data
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                hasCompletedOnboarding = true
                MaxStrengthStore.shared.update(data.maxStrength)
                // Save onboarding data to Firestore if authenticated
                Task {
                    if let uid = authManager.currentUser?.id {
                        do {
                            try await AuthService.shared.saveOnboardingData(data, for: uid)
                            _ = await OnboardingSyncService.shared.flushIfPossible(uid: uid)
                        } catch {
                            OnboardingSyncService.shared.enqueue(data)
                        }
                    } else {
                        OnboardingSyncService.shared.enqueue(data)
                    }
                }
            }
            .transition(.opacity)
        } else if !authManager.isAuthenticated || authManager.isAnonymous {
            AuthView()
                .transition(.opacity)
        } else {
            MainTabView()
                .transition(.opacity)
        }
    }
}
