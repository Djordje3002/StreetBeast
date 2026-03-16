import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var onboardingData = OnboardingResponse()
    @ObservedObject var design = DesignSystem.shared
    
    let onComplete: (OnboardingResponse) -> Void
    
    private let totalSteps = 9 // Welcome, Language, Name, Level, Max Strength, Feedback, Walkthrough x3
    
    var body: some View {
        ZStack {
            ZStack {
                design.backgroundColor

                LinearGradient(
                    colors: [
                        design.accentColor.opacity(0.12),
                        design.backgroundColor,
                        design.backgroundColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle(tint: design.accentColor))
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                
                TabView(selection: $currentStep) {
                    // Step 0: Welcome
                    FeaturesScreen(onNext: { currentStep = 1 })
                        .tag(0)

                    // Step 1: Language Selection
                    LanguageSelectionQuestion(onNext: { currentStep = 2 })
                        .tag(1)

                    // Step 2: Name
                    NameQuestion(name: $onboardingData.name, onNext: { currentStep = 3 })
                        .tag(2)

                    // Step 3: Workout Level
                    WorkoutLevelQuestion(selectedLevel: $onboardingData.workoutLevel, onNext: { currentStep = 4 })
                        .tag(3)

                    // Step 4: Current Max Strength
                    MaxStrengthQuestion(maxStrength: $onboardingData.maxStrength, onNext: { currentStep = 5 })
                        .tag(4)

                    // Step 5: Feedback + Badge
                    StrengthFeedbackView(onNext: { currentStep = 6 })
                        .tag(5)

                    // Step 6: Walkthrough - Timer
                    WalkthroughScreen(
                        icon: "timer",
                        title: LocalizationManager.shared.localized("onboarding_walkthrough_timer_title"),
                        subtitle: LocalizationManager.shared.localized("onboarding_walkthrough_timer_subtitle"),
                        buttonTitle: LocalizationManager.shared.localized("onboarding_continue"),
                        onNext: { currentStep = 7 }
                    )
                    .tag(6)

                    // Step 7: Walkthrough - Progress
                    WalkthroughScreen(
                        icon: "chart.line.uptrend.xyaxis",
                        title: LocalizationManager.shared.localized("onboarding_walkthrough_progress_title"),
                        subtitle: LocalizationManager.shared.localized("onboarding_walkthrough_progress_subtitle"),
                        buttonTitle: LocalizationManager.shared.localized("onboarding_continue"),
                        onNext: { currentStep = 8 }
                    )
                    .tag(7)

                    // Step 8: Walkthrough - Compete
                    WalkthroughScreen(
                        icon: "trophy.fill",
                        title: LocalizationManager.shared.localized("onboarding_walkthrough_compete_title"),
                        subtitle: LocalizationManager.shared.localized("onboarding_walkthrough_compete_subtitle"),
                        buttonTitle: LocalizationManager.shared.localized("onboarding_enter"),
                        onNext: { onComplete(onboardingData) }
                    )
                    .tag(8)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .dynamicTypeSize(.medium ... .accessibility3)
    }
}


#Preview {
    OnboardingView { response in
        // Preview stub: you can inspect the response here if needed
        print("Onboarding completed in preview with: \(response)")
    }
}
    
