import SwiftUI
import UniformTypeIdentifiers

struct TrainingPlansView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var planStore = TrainingPlanStore.shared
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    let selectedPlanId: UUID
    let startCreating: Bool
    let onSelect: (TrainingPlan) -> Void

    @State private var isBuilderPresented = false
    @State private var previewPlan: TrainingPlan?

    var body: some View {
        NavigationStack {
            ZStack {
                StreetBeastBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        activePlanCard
                        createPlanCard
                        quickTemplatesSection
                        builtInPlansSection
                        customPlansSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.lg)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle(localization.localized("training_plans_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localized("cancel")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isBuilderPresented) {
                TrainingPlanBuilderView { plan in
                    planStore.save(plan: plan)
                    onSelect(plan)
                    dismiss()
                }
            }
            .sheet(item: $previewPlan) { plan in
                TrainingPlanPreviewSheet(plan: plan) {
                    onSelect(plan)
                    dismiss()
                }
            }
        }
        .onAppear {
            if startCreating {
                isBuilderPresented = true
            }
        }
    }

    private var activePlanCard: some View {
        Group {
            if let plan = activePlan {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Text(localization.localized("training_plans_active_label"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(design.secondaryTextColor)
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(displayName(for: plan))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(design.textColor)
                        .lineLimit(1)

                    Spacer()

                    planMetaChip(icon: "timer", text: shortDuration(plan.totalDurationSeconds), isSelected: true)
                    planMetaChip(icon: "scope", text: planFocus(for: plan), isSelected: true)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .fill(design.accentColor.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .strokeBorder(design.accentColor.opacity(0.45), lineWidth: 1)
                )
                .shadow(color: design.accentColor.opacity(0.18), radius: 10, x: 0, y: 4)
            }
        }
    }

    private var createPlanCard: some View {
        Button {
            isBuilderPresented = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.md) {
                Circle()
                    .fill(design.accentColor.opacity(0.18))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(design.accentColor)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localized("training_plan_create"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(design.textColor)

                    Text(localization.localized("training_plans_subtitle"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(design.secondaryTextColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(design.secondaryTextColor)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(design.paperColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(design.accentColor.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var quickTemplatesSection: some View {
        SectionBlock(title: localization.localized("training_plans_quick_title")) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text(localization.localized("training_plans_quick_subtitle"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(design.secondaryTextColor)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(quickTemplates) { template in
                            quickTemplateCard(template)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
            }
        }
    }

    private var builtInPlansSection: some View {
        SectionBlock(title: localization.localized("training_plans_default_title")) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(filteredBuiltInPlans) { plan in
                    planRow(plan, isCustom: false)
                }
            }
        }
    }

    private var customPlansSection: some View {
        SectionBlock(title: localization.localized("training_plans_custom_title")) {
            if planStore.customPlans.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(Array(quickTemplates.prefix(2))) { template in
                            quickTemplateMiniCard(template)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
            } else {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(planStore.customPlans) { plan in
                        planRow(plan, isCustom: true)
                            .contextMenu {
                                Button {
                                    duplicatePlan(plan)
                                } label: {
                                    Text(localization.localized("training_plan_duplicate"))
                                }

                                Button(role: .destructive) {
                                    planStore.delete(plan: plan)
                                } label: {
                                    Text(localization.localized("training_plan_delete"))
                                }
                            }
                    }
                }
            }
        }
    }

    private func planRow(_ plan: TrainingPlan, isCustom: Bool) -> some View {
        let isSelected = plan.id == selectedPlanId
        let stepsText = String(format: localization.localized("training_plan_steps_format"), plan.totalStepInstances)
        let totalTime = shortDuration(plan.totalDurationSeconds)
        let leadingIcon = isCustom ? "pencil.line" : "bolt.fill"
        let focusText = planFocus(for: plan)
        let verticalPadding = isSelected ? DesignSystem.Spacing.lg + 4 : DesignSystem.Spacing.lg

        return HStack(spacing: DesignSystem.Spacing.md) {
            RoundedRectangle(cornerRadius: 14)
                .fill(design.accentColor.opacity(0.18))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: leadingIcon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(design.accentColor)
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(displayName(for: plan))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(design.textColor)

                    if isSelected {
                        Text(localization.localized("training_plan_selected_badge"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(design.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(design.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    planMetaChip(icon: "list.number", text: stepsText, isSelected: isSelected)
                    planMetaChip(icon: "timer", text: totalTime, isSelected: isSelected)
                    planMetaChip(icon: "scope", text: focusText, isSelected: isSelected)

                    Button {
                        previewPlan = plan
                    } label: {
                        planMetaChip(icon: "eye", text: localization.localized("training_plan_preview_action"), isSelected: false)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(design.accentColor)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(isSelected ? design.accentColor.opacity(0.12) : design.paperColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .strokeBorder(isSelected ? design.accentColor.opacity(0.45) : design.accentColor.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: design.accentColor.opacity(isSelected ? 0.18 : 0.06), radius: isSelected ? 12 : 6, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(plan)
            dismiss()
        }
        .accessibilityAddTraits(.isButton)
    }

    private var filteredBuiltInPlans: [TrainingPlan] {
        TrainingPlan.builtIns.filter { !isBeginnerPlan($0) }
    }

    private func isBeginnerPlan(_ plan: TrainingPlan) -> Bool {
        if plan.nameKey == "home_workout_beginner" { return true }
        return plan.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "beginner workout"
    }

    private func planMetaChip(icon: String, text: String, isSelected: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(design.accentColor)

            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? design.accentColor.opacity(0.12) : design.secondaryTextColor.opacity(0.08))
        .clipShape(Capsule())
    }

    private func quickTemplateCard(_ plan: TrainingPlan) -> some View {
        Button {
            let created = templatePlan(from: plan)
            planStore.save(plan: created)
            onSelect(created)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text(displayName(for: plan))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)

                Text(planFocus(for: plan))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(design.accentColor)

                Text(shortDuration(plan.totalDurationSeconds))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)
            }
            .padding(DesignSystem.Spacing.md)
            .frame(width: 170, alignment: .leading)
            .background(design.paperColor)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(design.accentColor.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        }
        .buttonStyle(.plain)
    }

    private func quickTemplateMiniCard(_ plan: TrainingPlan) -> some View {
        Button {
            let created = templatePlan(from: plan)
            planStore.save(plan: created)
            onSelect(created)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(displayName(for: plan))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)

                Text(shortDuration(plan.totalDurationSeconds))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(design.secondaryTextColor)
            }
            .padding(DesignSystem.Spacing.md)
            .frame(width: 150, alignment: .leading)
            .background(design.paperColor)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .strokeBorder(design.accentColor.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        }
        .buttonStyle(.plain)
    }

    private func displayName(for plan: TrainingPlan) -> String {
        if let key = plan.nameKey {
            return localization.localized(key)
        }
        return plan.name
    }

    private func planFocus(for plan: TrainingPlan) -> String {
        let exerciseCategories = plan.steps.compactMap { step -> ExerciseCategory? in
            guard step.kind == .exercise else { return nil }
            if let exerciseId = step.exerciseId,
               let exercise = Exercise.library.first(where: { $0.id == exerciseId }) {
                return exercise.category
            }
            if let exercise = Exercise.library.first(where: { $0.name == step.exerciseName }) {
                return exercise.category
            }
            return nil
        }

        guard !exerciseCategories.isEmpty else {
            return localization.localized("training_plan_focus_mixed")
        }

        let counts = Dictionary(grouping: exerciseCategories, by: { $0 }).mapValues { $0.count }
        let sorted = counts.sorted { $0.value > $1.value }

        if sorted.count > 1, sorted[0].value == sorted[1].value {
            return localization.localized("training_plan_focus_mixed")
        }

        return localization.localized(sorted[0].key.titleKey)
    }

    private func shortDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return String(format: localization.localized("timer_seconds_format"), seconds)
        }
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    private var activePlan: TrainingPlan? {
        let allPlans = TrainingPlan.builtIns + planStore.customPlans
        return allPlans.first { $0.id == selectedPlanId }
    }

    private var quickTemplates: [TrainingPlan] {
        [
            TrainingPlan(
                name: localization.localized("training_plans_quick_push_pull_legs"),
                prepareSeconds: 10,
                steps: [
                    templateExerciseStep("Pushups", seconds: 45),
                    templateRestStep(20),
                    templateExerciseStep("Pull-ups", seconds: 45),
                    templateRestStep(20),
                    templateExerciseStep("Squats", seconds: 45),
                    templateRestStep(20),
                    templateExerciseStep("Dips", seconds: 45)
                ]
            ),
            TrainingPlan(
                name: localization.localized("training_plans_quick_beginner_full_body"),
                prepareSeconds: 10,
                steps: [
                    templateExerciseStep("Pushups", seconds: 40),
                    templateRestStep(20),
                    templateExerciseStep("Squats", seconds: 45),
                    templateRestStep(20),
                    templateExerciseStep("Plank", seconds: 40),
                    templateRestStep(20),
                    templateExerciseStep("Bar Pushups (Incline Pushups)", seconds: 40)
                ]
            ),
            TrainingPlan(
                name: localization.localized("training_plans_quick_strength_builder"),
                prepareSeconds: 10,
                steps: [
                    templateExerciseStep("Pull-ups", seconds: 60),
                    templateRestStep(30),
                    templateExerciseStep("Dips", seconds: 60),
                    templateRestStep(30),
                    templateExerciseStep("Pushups", seconds: 60),
                    templateRestStep(30),
                    templateExerciseStep("Squats", seconds: 60)
                ]
            )
        ]
    }

    private func templateExerciseStep(_ name: String, seconds: Int) -> TrainingStep {
        let exercise = Exercise.library.first { $0.name == name }
        return TrainingStep(kind: .exercise, exercise: exercise, exerciseName: name, durationSeconds: seconds)
    }

    private func templateRestStep(_ seconds: Int) -> TrainingStep {
        TrainingStep(kind: .rest, exerciseName: "", durationSeconds: seconds)
    }

    private func templatePlan(from plan: TrainingPlan) -> TrainingPlan {
        TrainingPlan(
            name: uniquePlanName(base: displayName(for: plan)),
            nameKey: nil,
            prepareSeconds: plan.prepareSeconds,
            steps: plan.steps
        )
    }

    private func uniquePlanName(base: String) -> String {
        let existingNames = Set(planStore.customPlans.map { $0.name })
        if !existingNames.contains(base) {
            return base
        }
        var attempt = 2
        while existingNames.contains("\(base) \(attempt)") {
            attempt += 1
        }
        return "\(base) \(attempt)"
    }

    private func duplicatePlan(_ plan: TrainingPlan) {
        let copy = TrainingPlan(
            name: uniquePlanName(base: displayName(for: plan)),
            nameKey: nil,
            prepareSeconds: plan.prepareSeconds,
            steps: plan.steps
        )
        planStore.save(plan: copy)
        onSelect(copy)
    }
}

private struct TrainingPlanBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    let onSave: (TrainingPlan) -> Void

    @State private var planName: String = ""
    @State private var prepareSeconds: Int = 10
    @State private var steps: [TrainingStep] = []

    @State private var isStepEditorPresented = false
    @State private var editingIndex: Int? = nil
    @State private var showsRestSteps = false
    @State private var draggedStep: TrainingStep? = nil
    @State private var durationEditor: DurationEditorItem? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                StreetBeastBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        planInfoCard
                        stepsCard

                        PrimaryActionButton(
                            title: localization.localized("training_plan_save"),
                            action: savePlan,
                            isEnabled: isSaveEnabled,
                            backgroundColor: isSaveEnabled ? design.accentColor : .gray
                        )
                        .padding(.top, DesignSystem.Spacing.sm)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.lg)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle(localization.localized("training_plan_builder_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localized("cancel")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isStepEditorPresented) {
                TrainingStepEditorView(step: editingIndex.flatMap { steps[safe: $0] }) { step in
                    if let index = editingIndex, steps.indices.contains(index) {
                        steps[index] = step
                    } else {
                        steps.append(step)
                    }
                    editingIndex = nil
                }
            }
            .sheet(item: $durationEditor) { item in
                DurationQuickEditSheet(
                    title: durationEditorTitle(for: item.id),
                    duration: durationBinding(for: item.id),
                    onDismiss: { durationEditor = nil },
                    formatDuration: shortDuration
                )
            }
        }
    }

    private var planInfoCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized("training_plan_name_label"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)
                    .textCase(.uppercase)
                    .tracking(1)

                TextField(localization.localized("training_plan_name_placeholder"), text: $planName)
                    .textFieldStyle(ModernTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized("training_plan_prepare_label"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)
                    .textCase(.uppercase)
                    .tracking(1)

                Stepper(value: $prepareSeconds, in: 0...300, step: 5) {
                    Text(shortDuration(prepareSeconds))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(design.textColor)
                }
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                durationChip(text: String(format: localization.localized("training_plan_steps_format"), totalStepInstances))
                durationChip(text: shortDuration(totalDurationSeconds))
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .streetBeastSurface()
    }

    private var stepsCard: some View {
        let visibleSteps = showsRestSteps ? steps : steps.filter { $0.kind != .rest }
        let restSummary = restSummaryText
        let canReorder = showsRestSteps || steps.allSatisfy { $0.kind != .rest }

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text(localization.localized("training_plan_steps_title"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)

                Spacer()

                Text(String(format: localization.localized("training_plan_steps_format"), totalStepInstances))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)
            }

            Toggle(isOn: $showsRestSteps) {
                Text(localization.localized("training_plan_include_rest"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(design.textColor)
            }
            .toggleStyle(SwitchToggleStyle(tint: design.accentColor))

            if !showsRestSteps, let restSummary {
                Text(restSummary)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)
            }

            if steps.isEmpty {
                VStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(design.accentColor)

                    Text(localization.localized("training_plan_steps_empty"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(design.textColor)

                    Text(localization.localized("training_plan_steps_empty_hint"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(design.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } else {
                SettingsCardGroup {
                    ForEach(Array(visibleSteps.enumerated()), id: \.element.id) { visibleIndex, step in
                        let index = steps.firstIndex { $0.id == step.id } ?? visibleIndex
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: DesignSystem.Spacing.md) {
                                if canReorder {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(design.secondaryTextColor)
                                }

                                Circle()
                                    .fill(design.accentColor.opacity(0.15))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Text("\(visibleIndex + 1)")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(design.accentColor)
                                    )

                                Text(stepTitle(step))
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(design.textColor)
                                    .lineLimit(1)

                                Spacer()

                                if step.kind == .exercise, step.repeatCount > 1 {
                                    repeatChip(text: "x\(step.repeatCount)")
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingIndex = index
                                isStepEditorPresented = true
                            }

                            HStack(spacing: DesignSystem.Spacing.md) {
                                Button {
                                    durationEditor = DurationEditorItem(id: step.id)
                                } label: {
                                    durationChip(text: shortDuration(step.durationSeconds))
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button(role: .destructive) {
                                    steps.removeAll { $0.id == step.id }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(design.secondaryTextColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .onDrag {
                            guard canReorder else { return NSItemProvider() }
                            draggedStep = step
                            return NSItemProvider(object: step.id.uuidString as NSString)
                        }
                        .onDrop(of: [UTType.text], delegate: StepDropDelegate(
                            item: step,
                            items: $steps,
                            draggedItem: $draggedStep,
                            isEnabled: canReorder
                        ))

                        if visibleIndex < visibleSteps.count - 1 {
                            SettingsRowDivider()
                        }
                    }
                }
            }

            Button {
                editingIndex = nil
                isStepEditorPresented = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(design.paperColor)

                    Text(localization.localized("training_plan_add_step"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(design.paperColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [design.accentColor, design.accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(design.accentColor.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                .shadow(color: design.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.Spacing.lg)
        .streetBeastSurface()
    }

    private var isSaveEnabled: Bool {
        !planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !steps.isEmpty
    }

    private func savePlan() {
        let trimmed = planName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !steps.isEmpty else { return }

        let plan = TrainingPlan(
            name: trimmed,
            prepareSeconds: prepareSeconds,
            steps: steps
        )
        onSave(plan.normalized())
        dismiss()
    }

    private func stepTitle(_ step: TrainingStep) -> String {
        if step.kind == .rest {
            return localization.localized("training_plan_step_rest")
        }
        return step.exerciseName
    }

    private func durationBinding(for id: UUID) -> Binding<Int> {
        Binding(
            get: { steps.first(where: { $0.id == id })?.durationSeconds ?? 0 },
            set: { newValue in
                if let index = steps.firstIndex(where: { $0.id == id }) {
                    steps[index].durationSeconds = newValue
                }
            }
        )
    }

    private func durationEditorTitle(for id: UUID) -> String {
        if let step = steps.first(where: { $0.id == id }) {
            return stepTitle(step)
        }
        return localization.localized("training_plan_step_duration")
    }

    private func durationChip(text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(design.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(design.accentColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private func repeatChip(text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(design.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(design.paperColor.opacity(0.8))
            .overlay(
                Capsule()
                    .stroke(design.accentColor.opacity(0.25), lineWidth: 1)
            )
            .clipShape(Capsule())
    }

    private var totalStepInstances: Int {
        steps.reduce(0) { $0 + max($1.repeatCount, 1) }
    }

    private var totalDurationSeconds: Int {
        max(prepareSeconds, 0) + steps.reduce(0) { total, step in
            total + (max(step.durationSeconds, 0) * max(step.repeatCount, 1))
        }
    }

    private var restSummaryText: String? {
        let restSteps = steps.filter { $0.kind == .rest }
        guard !restSteps.isEmpty else { return nil }

        let durations = restSteps.map { $0.durationSeconds }
        let uniqueDurations = Set(durations)
        if uniqueDurations.count == 1, let duration = uniqueDurations.first {
            return String(format: localization.localized("training_plan_rest_summary_format"), restSteps.count, shortDuration(duration))
        }

        let total = restSteps.reduce(0) { $0 + max($1.durationSeconds, 0) }
        return String(format: localization.localized("training_plan_rest_summary_total_format"), restSteps.count, shortDuration(total))
    }

    private func shortDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return String(format: localization.localized("timer_seconds_format"), seconds)
        }
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
}

private struct TrainingStepEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    let initialStep: TrainingStep?
    let onSave: (TrainingStep) -> Void

    @State private var kind: TrainingStepKind
    @State private var selectedExerciseId: String
    @State private var durationSeconds: Int
    @State private var repeatCount: Int

    private let exercises = Exercise.library

    init(step: TrainingStep?, onSave: @escaping (TrainingStep) -> Void) {
        self.initialStep = step
        self.onSave = onSave

        let fallbackExerciseId = Exercise.library.first?.id ?? ""
        let initialExerciseId = step?.exerciseId
            ?? Exercise.library.first(where: { $0.name == step?.exerciseName })?.id
            ?? fallbackExerciseId
        _kind = State(initialValue: step?.kind ?? .exercise)
        _selectedExerciseId = State(initialValue: initialExerciseId)
        _durationSeconds = State(initialValue: max(step?.durationSeconds ?? 60, 5))
        _repeatCount = State(initialValue: max(step?.repeatCount ?? 1, 1))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StreetBeastBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        stepTypeCard

                        if kind == .exercise {
                            exercisePickerCard
                        }

                        durationCard

                        if kind == .exercise {
                            repeatCard
                        }

                        PrimaryActionButton(
                            title: localization.localized("training_plan_save"),
                            action: saveStep
                        )
                        .padding(.top, DesignSystem.Spacing.sm)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.lg)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle(localization.localized("training_plan_step_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localized("cancel")) {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: kind) { _, newValue in
            if newValue == .rest {
                repeatCount = 1
            }
        }
    }

    private var stepTypeCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(localization.localized("training_plan_step_type"))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(1)

            Picker("", selection: $kind) {
                Text(localization.localized("training_plan_step_exercise")).tag(TrainingStepKind.exercise)
                Text(localization.localized("training_plan_step_rest")).tag(TrainingStepKind.rest)
            }
            .pickerStyle(.segmented)
        }
        .padding(DesignSystem.Spacing.lg)
        .streetBeastSurface()
    }

    private var exercisePickerCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(localization.localized("training_plan_step_exercise"))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(1)

            Picker("", selection: $selectedExerciseId) {
                ForEach(exercises) { exercise in
                    Text(exercise.name).tag(exercise.id)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(DesignSystem.Spacing.lg)
        .streetBeastSurface()
    }

    private var durationCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(localization.localized("training_plan_step_duration"))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(1)

            Stepper(value: $durationSeconds, in: 5...600, step: 5) {
                Text(shortDuration(durationSeconds))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .streetBeastSurface()
    }

    private var repeatCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(localization.localized("training_plan_step_repeats"))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(1)

            Stepper(value: $repeatCount, in: 1...20, step: 1) {
                Text("x\(repeatCount)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .streetBeastSurface()
    }

    private func saveStep() {
        let stepId = initialStep?.id ?? UUID()
        let exercise = exercises.first { $0.id == selectedExerciseId }

        let newStep = TrainingStep(
            id: stepId,
            kind: kind,
            exercise: kind == .exercise ? exercise : nil,
            exerciseName: kind == .exercise ? (exercise?.name ?? "") : "",
            durationSeconds: durationSeconds,
            repeatCount: kind == .exercise ? repeatCount : 1
        )

        onSave(newStep)
        dismiss()
    }

    private func shortDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return String(format: localization.localized("timer_seconds_format"), seconds)
        }
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
}

private struct DurationEditorItem: Identifiable {
    let id: UUID
}

private struct DurationQuickEditSheet: View {
    let title: String
    @Binding var duration: Int
    let onDismiss: () -> Void
    let formatDuration: (Int) -> String

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                StreetBeastBackground()

                VStack(spacing: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(design.textColor)

                        Text(localization.localized("training_plan_step_duration"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(design.secondaryTextColor)
                            .textCase(.uppercase)
                            .tracking(1)

                        Stepper(value: $duration, in: 5...600, step: 5) {
                            Text(formatDuration(duration))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(design.textColor)
                        }

                        Slider(value: Binding(
                            get: { Double(duration) },
                            set: { duration = Int($0.rounded()) }
                        ), in: 5...600, step: 5)
                        .tint(design.accentColor)
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .streetBeastSurface()

                    PrimaryActionButton(
                        title: localization.localized("training_plan_duration_done"),
                        action: {
                            onDismiss()
                            dismiss()
                        }
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .navigationTitle(localization.localized("training_plan_duration_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localized("cancel")) {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct StepDropDelegate: DropDelegate {
    let item: TrainingStep
    @Binding var items: [TrainingStep]
    @Binding var draggedItem: TrainingStep?
    let isEnabled: Bool

    func dropEntered(info: DropInfo) {
        guard isEnabled, let draggedItem, draggedItem != item else { return }
        guard let fromIndex = items.firstIndex(of: draggedItem),
              let toIndex = items.firstIndex(of: item) else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
}

private struct TrainingPlanPreviewSheet: View {
    let plan: TrainingPlan
    let onSelect: () -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                StreetBeastBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(displayName(for: plan))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(design.textColor)

                            HStack(spacing: 8) {
                                Text(String(format: localization.localized("training_plan_steps_format"), plan.totalStepInstances))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(design.secondaryTextColor)

                                Text(planFocus(for: plan))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(design.accentColor)
                            }
                        }

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text(localization.localized("training_plan_preview_total"))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(design.secondaryTextColor)
                                .textCase(.uppercase)
                                .tracking(1)

                            Text(shortDuration(plan.totalDurationSeconds))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(design.textColor)
                        }

                        SectionBlock(title: localization.localized("training_plan_preview_steps")) {
                            SettingsCardGroup {
                                ForEach(Array(plan.steps.enumerated()), id: \.element.id) { index, step in
                                    HStack(spacing: DesignSystem.Spacing.md) {
                                        previewStepThumbnail(step: step)

                                        Circle()
                                            .fill(design.accentColor.opacity(0.15))
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Text("\(index + 1)")
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundColor(design.accentColor)
                                            )

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(stepTitle(step))
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundColor(design.textColor)

                                            HStack(spacing: 8) {
                                                Text(shortDuration(step.durationSeconds))
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(design.secondaryTextColor)

                                                if step.kind == .exercise, step.repeatCount > 1 {
                                                    Text("x\(step.repeatCount)")
                                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                                        .foregroundColor(design.accentColor)
                                                }
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                                    .padding(.vertical, DesignSystem.Spacing.sm)

                                    if index < plan.steps.count - 1 {
                                        SettingsRowDivider()
                                    }
                                }
                            }
                        }

                        PrimaryActionButton(
                            title: localization.localized("training_plan_preview_select"),
                            action: {
                                onSelect()
                                dismiss()
                            }
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.lg)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle(localization.localized("training_plan_preview_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localized("cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func displayName(for plan: TrainingPlan) -> String {
        if let key = plan.nameKey {
            return localization.localized(key)
        }
        return plan.name
    }

    private func stepTitle(_ step: TrainingStep) -> String {
        if step.kind == .rest {
            return localization.localized("training_plan_step_rest")
        }
        return step.exerciseName
    }

    private func exerciseForStep(_ step: TrainingStep) -> Exercise? {
        if let id = step.exerciseId,
           let exercise = Exercise.library.first(where: { $0.id == id }) {
            return exercise
        }
        return Exercise.library.first(where: { $0.name == step.exerciseName })
    }

    @ViewBuilder
    private func previewStepThumbnail(step: TrainingStep) -> some View {
        let imageName = exerciseForStep(step)?.imageName
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(design.accentColor.opacity(0.12))
                .frame(width: 46, height: 46)

            if let imageName, step.kind == .exercise {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: step.kind == .rest ? "pause.fill" : "figure.strengthtraining.traditional")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(design.accentColor)
            }
        }
    }

    private func shortDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return String(format: localization.localized("timer_seconds_format"), seconds)
        }
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    private func planFocus(for plan: TrainingPlan) -> String {
        let exerciseCategories = plan.steps.compactMap { step -> ExerciseCategory? in
            guard step.kind == .exercise else { return nil }
            return exerciseForStep(step)?.category
        }

        guard !exerciseCategories.isEmpty else {
            return localization.localized("training_plan_focus_mixed")
        }

        let counts = Dictionary(grouping: exerciseCategories, by: { $0 }).mapValues(\.count)
        let sorted = counts.sorted { $0.value > $1.value }

        if sorted.count > 1, sorted[0].value == sorted[1].value {
            return localization.localized("training_plan_focus_mixed")
        }

        return localization.localized(sorted[0].key.titleKey)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
