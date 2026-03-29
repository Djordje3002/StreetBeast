import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var isPlanPickerPresented = false
    @State private var isExercisesPresented = false
    @State private var startCreatingPlan = false

    var body: some View {
        ScreenScaffold(
            contentTopPadding: 110,
            horizontalPadding: DesignSystem.Spacing.lg,
            bottomPadding: 140,
            header: {
                EmptyView()
            },
            content: {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    NavigationLink {
                        TimerSessionView(viewModel: viewModel)
                    } label: {
                        timerRingSection
                    }
                    .buttonStyle(.plain)
                    makeTrainingCard
                    trainingPlanSection
                    planStepsSection
                    exerciseLibrarySection
                }
            }
        )
        .dynamicTypeSize(.medium ... .accessibility3)
        .sheet(isPresented: $isPlanPickerPresented) {
            TrainingPlansView(
                selectedPlanId: viewModel.selectedPlan.id,
                startCreating: startCreatingPlan
            ) { plan in
                viewModel.applyPlan(plan)
            }
            .onDisappear {
                startCreatingPlan = false
            }
        }
        .sheet(isPresented: $isExercisesPresented) {
            ExercisesView()
        }
    }
}

// MARK: - Timer Ring
private extension TimerView {
    var makeTrainingCard: some View {
        Button {
            startCreatingPlan = true
            isPlanPickerPresented = true
        } label: {
            NavigationSurfaceCard(
                spacing: DesignSystem.Spacing.md,
                horizontalPadding: DesignSystem.Spacing.lg,
                verticalPadding: DesignSystem.Spacing.lg,
                showChevron: true,
                style: .clean,
                leading: {
                    Circle()
                        .fill(design.accentColor.opacity(0.18))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(design.accentColor)
                        )
                },
                content: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.localized("training_plan_create"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(design.textColor)

                        Text(localization.localized("training_plans_subtitle"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(design.secondaryTextColor)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    var currentStepTitle: String? {
        guard viewModel.currentPhase != .prepare && viewModel.currentPhase != .complete else { return nil }
        guard let step = viewModel.currentStep else { return nil }
        if step.kind == .rest {
            return nextExerciseName ?? localization.localized("timer_phase_rest")
        }
        return step.exerciseName
    }

    var timerRingSection: some View {
        ZStack {
            Circle()
                .stroke(design.accentColor.opacity(0.12), lineWidth: 18)

            Circle()
                .trim(from: 0, to: viewModel.phaseProgress)
                .stroke(
                    LinearGradient(
                        colors: [design.flameColor, design.accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: design.accentColor.opacity(0.25), radius: 10, x: 0, y: 4)

            Rectangle()
                .fill(design.accentColor)
                .frame(width: 2, height: 14)
                .offset(y: -130)

            VStack(spacing: 6) {
                Text(localization.localized(viewModel.currentPhase.titleKey))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(design.candleColor)

                Text(viewModel.formattedTime(viewModel.remainingSeconds))
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundColor(design.textColor)

                if let stepTitle = currentStepTitle {
                    Text(stepTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(design.accentColor)
                }

                Text(localization.localized("timer_total_time"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)

                Text(viewModel.formattedTime(viewModel.totalTimeSeconds))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(design.accentColor)
            }
        }
        .frame(width: 260, height: 260)
        .contentShape(Circle())
        .padding(.top, DesignSystem.Spacing.sm)
    }
}

// MARK: - Training Plan
private extension TimerView {
    var trainingPlanSection: some View {
        SectionBlock(title: localization.localized("training_plan_selected_title")) {
            Button {
                startCreatingPlan = false
                isPlanPickerPresented = true
            } label: {
                NavigationSurfaceCard(
                    spacing: DesignSystem.Spacing.md,
                    horizontalPadding: DesignSystem.Spacing.lg,
                    verticalPadding: DesignSystem.Spacing.lg,
                    showChevron: true,
                    style: .clean,
                    leading: {
                        Circle()
                            .fill(design.accentColor.opacity(0.18))
                            .frame(width: 46, height: 46)
                            .overlay(
                                Image(systemName: "flag.checkered")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(design.accentColor)
                            )
                    },
                    content: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(planDisplayName)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(design.textColor)

                            Text(planSummary)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(design.secondaryTextColor)
                        }
                    }
                )
            }
            .buttonStyle(.plain)
        }
    }

    var planStepsSection: some View {
        SectionBlock(title: localization.localized("training_plan_steps_title")) {
            let visibleSteps = viewModel.selectedPlan.steps.enumerated().filter { $0.element.kind != .rest }

            if visibleSteps.isEmpty {
                Text(localization.localized("training_plan_steps_empty"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(design.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                SettingsCardGroup {
                    ForEach(Array(visibleSteps.enumerated()), id: \.element.element.id) { position, entry in
                        let index = entry.offset
                        let step = entry.element
                        let isSelected = isCurrentStep(index)

                        HStack(spacing: DesignSystem.Spacing.md) {
                            planStepThumbnail(step: step, isSelected: isSelected)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(stepTitle(step))
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(isSelected ? .white : design.textColor)

                                HStack(spacing: 8) {
                                    Text(shortDuration(step.durationSeconds))
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(isSelected ? .white.opacity(0.85) : design.secondaryTextColor)

                                    if step.kind == .exercise, step.repeatCount > 1 {
                                        Text("x\(step.repeatCount)")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(isSelected ? .white.opacity(0.9) : design.accentColor)
                                    }
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(isSelected ? design.accentColor : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))

                        if position < visibleSteps.count - 1 {
                            SettingsRowDivider()
                        }
                    }
                }
            }
        }
    }

    var planDisplayName: String {
        if let key = viewModel.selectedPlan.nameKey {
            return localization.localized(key)
        }
        return viewModel.selectedPlan.name
    }

    var planSummary: String {
        let stepCount = String(format: localization.localized("training_plan_steps_format"), viewModel.selectedPlan.totalStepInstances)
        let totalTime = viewModel.formattedTime(viewModel.selectedPlan.totalDurationSeconds)
        return "\(stepCount) • \(totalTime)"
    }

    func isCurrentStep(_ index: Int) -> Bool {
        guard viewModel.hasStarted,
              !viewModel.isCompleted,
              viewModel.currentPhase != .prepare
        else { return false }
        return viewModel.currentBaseStepIndex == index
    }

    func stepTitle(_ step: TrainingStep) -> String {
        if step.kind == .rest {
            return localization.localized("timer_phase_rest")
        }
        return step.exerciseName
    }

    func exerciseForStep(_ step: TrainingStep) -> Exercise? {
        if let id = step.exerciseId,
           let exercise = Exercise.library.first(where: { $0.id == id }) {
            return exercise
        }
        return Exercise.library.first(where: { $0.name == step.exerciseName })
    }

    @ViewBuilder
    func planStepThumbnail(step: TrainingStep, isSelected: Bool) -> some View {
        let imageName = exerciseForStep(step)?.imageName
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.white.opacity(0.2) : design.accentColor.opacity(0.12))
                .frame(width: 52, height: 52)

            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 46)
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? .white : design.accentColor)
            }
        }
    }

    func shortDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return String(format: localization.localized("timer_seconds_format"), seconds)
        }
        return viewModel.formattedTime(seconds)
    }
}

// MARK: - Exercises
private extension TimerView {
    var exerciseLibrarySection: some View {
        SectionBlock(title: localization.localized("exercises_title")) {
            Button {
                isExercisesPresented = true
            } label: {
                NavigationSurfaceCard(
                    spacing: DesignSystem.Spacing.md,
                    horizontalPadding: DesignSystem.Spacing.lg,
                    verticalPadding: DesignSystem.Spacing.lg,
                    showChevron: true,
                    style: .clean,
                    leading: {
                        Circle()
                            .fill(design.accentColor.opacity(0.18))
                            .frame(width: 46, height: 46)
                            .overlay(
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(design.accentColor)
                            )
                    },
                    content: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localization.localized("exercises_title"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(design.textColor)

                            Text(localization.localized("exercises_subtitle"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(design.secondaryTextColor)
                        }
                    }
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Timer Session
struct TimerSessionView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showSummary = false

    var body: some View {
        ScreenScaffold(
            contentTopPadding: 120,
            horizontalPadding: DesignSystem.Spacing.lg,
            bottomPadding: 140,
            header: {
                sessionHeader
            },
            content: {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    timerRingSection
                    currentExerciseSection
                    progressSection
                    actionButtons
                }
            }
        )
        .dynamicTypeSize(.medium ... .accessibility3)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.lastCompletedSession?.id) { _, newValue in
            if newValue != nil {
                showSummary = true
            }
        }
        .sheet(isPresented: $showSummary) {
            if let session = viewModel.lastCompletedSession {
                WorkoutSummaryView(
                    session: session,
                    onDone: {
                        showSummary = false
                        viewModel.reset()
                        dismiss()
                    },
                    onRestart: {
                        showSummary = false
                        viewModel.reset()
                        viewModel.start()
                    }
                )
            }
        }
    }
}

// MARK: - Timer Session Header
private extension TimerSessionView {
    var sessionHeader: some View {
        StreetBeastHeaderContainer(contentSpacing: 0) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(design.textColor)
                        .frame(width: 38, height: 38)
                        .background(design.paperColor.opacity(0.85))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(design.accentColor.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Text(localization.localized("timer_title"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(design.textColor)

                Spacer()
            }
        }
    }
}

// MARK: - Timer Session Ring
private extension TimerSessionView {
    var currentStepTitle: String? {
        guard viewModel.currentPhase != .prepare && viewModel.currentPhase != .complete else { return nil }
        guard let step = viewModel.currentStep else { return nil }
        if step.kind == .rest {
            return localization.localized("timer_phase_rest")
        }
        return step.exerciseName
    }

    var currentExerciseImageName: String? {
        if viewModel.currentPhase == .rest {
            return nextExerciseImageName
        }

        guard let step = viewModel.currentStep, step.kind == .exercise else { return nil }
        return imageName(for: step)
    }

    var nextExerciseImageName: String? {
        guard let nextStep = nextExerciseStep else { return nil }
        return imageName(for: nextStep)
    }

    var nextExerciseName: String? {
        guard let nextStep = nextExerciseStep else { return nil }
        return displayName(for: nextStep)
    }

    private var nextExerciseStep: TrainingStep? {
        let startIndex = viewModel.currentPhase == .prepare ? 0 : viewModel.currentStepIndex + 1
        return viewModel.nextExerciseStep(from: startIndex)
    }

    private func imageName(for step: TrainingStep) -> String? {
        if let id = step.exerciseId,
           let exercise = Exercise.library.first(where: { $0.id == id }) {
            return exercise.imageName
        }
        if let exercise = Exercise.library.first(where: { $0.name == step.exerciseName }) {
            return exercise.imageName
        }
        return nil
    }

    private func displayName(for step: TrainingStep) -> String? {
        if !step.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return step.exerciseName
        }
        if let id = step.exerciseId,
           let exercise = Exercise.library.first(where: { $0.id == id }) {
            return exercise.name
        }
        return nil
    }

    var timerRingSection: some View {
        ZStack {
            Circle()
                .stroke(design.accentColor.opacity(0.12), lineWidth: 18)

            Circle()
                .trim(from: 0, to: viewModel.phaseProgress)
                .stroke(
                    LinearGradient(
                        colors: [design.flameColor, design.accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: design.accentColor.opacity(0.25), radius: 10, x: 0, y: 4)

            Rectangle()
                .fill(design.accentColor)
                .frame(width: 2, height: 14)
                .offset(y: -130)

            VStack(spacing: 6) {
                Text(localization.localized(viewModel.currentPhase.titleKey))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(design.candleColor)

                Text(viewModel.formattedTime(viewModel.remainingSeconds))
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundColor(design.textColor)

                Text(localization.localized("timer_total_time"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)

                Text(viewModel.formattedTime(viewModel.totalTimeSeconds))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(design.accentColor)
            }
        }
        .frame(width: 260, height: 260)
        .padding(.top, DesignSystem.Spacing.sm)
    }

    var currentExerciseSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            if let stepTitle = currentStepTitle {
                Text(stepTitle)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(design.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            if viewModel.currentPhase == .rest, let nextName = nextExerciseName {
                Text(String(format: localization.localized("timer_next_format"), nextName))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(design.accentColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            if let imageName = currentExerciseImageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 140)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .fill(design.paperColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .strokeBorder(design.accentColor.opacity(0.12), lineWidth: 1)
                    )
            }

            if !upNextExercises.isEmpty {
                upNextSection
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    var upNextSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(localization.localized("timer_up_next_title"))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 10) {
                ForEach(Array(upNextExercises.enumerated()), id: \.element.id) { index, step in
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(design.accentColor.opacity(0.12))
                                .frame(width: 44, height: 44)

                            if let imageName = imageName(for: step) {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                            } else {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(design.accentColor)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName(for: step) ?? localization.localized("timer_phase_work"))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(design.textColor)

                            Text(shortDuration(step.durationSeconds))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(design.secondaryTextColor)
                        }

                        Spacer()

                        Text("#\(index + 1)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(design.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(design.accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, 10)
                    .background(design.paperColor.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .strokeBorder(design.accentColor.opacity(0.12), lineWidth: 1)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.md)
        .streetBeastSurface()
    }

    var upNextExercises: [TrainingStep] {
        if viewModel.currentPhase == .complete { return [] }

        let startIndex: Int
        if viewModel.currentPhase == .prepare {
            startIndex = 0
        } else {
            startIndex = viewModel.currentStepIndex + 1
        }

        return viewModel.upcomingExercises(from: startIndex, limit: 3)
    }

    private func shortDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return String(format: localization.localized("timer_seconds_format"), seconds)
        }
        return viewModel.formattedTime(seconds)
    }
}

// MARK: - Timer Session Progress
private extension TimerSessionView {
    var progressSection: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            TimerProgressStat(
                icon: "list.number",
                title: String(
                    format: localization.localized("timer_step_format"),
                    viewModel.currentStepNumber,
                    viewModel.totalSteps
                ),
                progress: viewModel.stepProgress,
                tint: design.candleColor
            )

            TimerProgressStat(
                icon: "flag.checkered",
                title: localization.localized("timer_plan_label"),
                progress: viewModel.planProgress,
                tint: design.accentColor
            )
        }
    }
}

// MARK: - Timer Session Actions
private extension TimerSessionView {
    var actionButtons: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Button(action: viewModel.reset) {
                Text(localization.localized("timer_reset"))
                    .font(DesignSystem.Typography.button)
                    .foregroundColor(design.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(design.paperColor.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(design.accentColor, lineWidth: 1)
                    )
            }
            .disabled(!viewModel.hasStarted)
            .opacity(viewModel.hasStarted ? 1 : 0.5)

            PrimaryActionButton(
                title: actionTitle,
                action: viewModel.toggleRunning,
                backgroundColor: design.accentColor
            )
        }
    }

    var actionTitle: String {
        if viewModel.isRunning {
            return localization.localized("timer_pause")
        }
        if viewModel.isCompleted {
            return localization.localized("timer_restart")
        }
        if viewModel.hasStarted {
            return localization.localized("timer_resume")
        }
        return localization.localized("timer_start")
    }
}

// MARK: - Components
private struct TimerProgressStat: View {
    let icon: String
    let title: String
    let progress: Double
    let tint: Color

    @ObservedObject private var design = DesignSystem.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(tint)

                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)
            }

            TimerProgressBar(progress: progress, tint: tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TimerProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(0.15))

                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * max(min(progress, 1), 0))
            }
        }
        .frame(height: 6)
    }
}

#Preview {
    TimerView()
}
