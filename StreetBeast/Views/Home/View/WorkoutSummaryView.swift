import SwiftUI

struct WorkoutSummaryView: View {
    let session: WorkoutSession
    let onDone: () -> Void
    let onRestart: () -> Void

    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        ScreenScaffold(
            contentTopPadding: 120,
            horizontalPadding: DesignSystem.Spacing.lg,
            bottomPadding: 140,
            header: {
                header
            },
            content: {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    heroCard
                    statsGrid
                    stepsSection
                    actionButtons
                }
            }
        )
        .dynamicTypeSize(.medium ... .accessibility3)
    }
}

private extension WorkoutSummaryView {
    var header: some View {
        StreetBeastHeaderContainer(contentSpacing: 0) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button(action: onDone) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
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

                Text(localization.localized("workout_summary_title"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(design.textColor)

                Spacer()
            }
        }
    }

    var heroCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(localization.localized("workout_summary_headline"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)

                Spacer()

                Text(session.completedAt, style: .date)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)
            }

            Text(planDisplayName)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(design.textColor)

            HStack(spacing: DesignSystem.Spacing.sm) {
                summaryPill(icon: "clock", text: formattedDuration(session.totalDurationSeconds))
                summaryPill(icon: "bolt.fill", text: String(format: localization.localized("workout_summary_xp_format"), WorkoutXP.xp(for: session)))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.lg)
        .background(
            LinearGradient(
                colors: [design.accentColor.opacity(0.18), design.paperColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .strokeBorder(design.accentColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: design.accentColor.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    var statsGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
            summaryStatTile(
                title: localization.localized("workout_summary_total_time"),
                value: formattedDuration(session.totalDurationSeconds),
                subtitle: localization.localized("workout_summary_total_time_subtitle"),
                icon: "timer",
                color: design.accentColor
            )

            summaryStatTile(
                title: localization.localized("workout_summary_work_time"),
                value: formattedDuration(session.workDurationSeconds),
                subtitle: localization.localized("workout_summary_work_time_subtitle"),
                icon: "flame.fill",
                color: design.flameColor
            )

            summaryStatTile(
                title: localization.localized("workout_summary_rest_time"),
                value: formattedDuration(session.restDurationSeconds),
                subtitle: localization.localized("workout_summary_rest_time_subtitle"),
                icon: "pause.fill",
                color: design.candleColor
            )

            summaryStatTile(
                title: localization.localized("workout_summary_steps"),
                value: String(session.workSteps),
                subtitle: localization.localized("workout_summary_steps_subtitle"),
                icon: "list.number",
                color: design.accentColor
            )
        }
    }

    var stepsSection: some View {
        SectionBlock(title: localization.localized("workout_summary_steps_title")) {
            if exerciseSteps.isEmpty {
                Text(localization.localized("workout_summary_steps_empty"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(design.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                SettingsCardGroup {
                    ForEach(Array(exerciseSteps.enumerated()), id: \.element.id) { index, step in
                        SettingsListRow(
                            icon: "figure.strengthtraining.traditional",
                            title: step.exerciseName,
                            isSelected: false
                        ) {
                            HStack(spacing: 8) {
                                Text(shortDuration(step.durationSeconds))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(design.secondaryTextColor)

                                if step.repeatCount > 1 {
                                    Text("x\(step.repeatCount)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(design.accentColor)
                                }
                            }
                        }

                        if index < exerciseSteps.count - 1 {
                            SettingsRowDivider()
                        }
                    }
                }
            }

            if let restSummary {
                Text(restSummary)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, DesignSystem.Spacing.sm)
            }
        }
    }

    var actionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            PrimaryActionButton(
                title: localization.localized("workout_summary_train_again"),
                action: onRestart,
                backgroundColor: design.accentColor
            )

            Button(action: onDone) {
                Text(localization.localized("workout_summary_done"))
                    .font(DesignSystem.Typography.button)
                    .foregroundColor(design.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(design.paperColor.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(design.accentColor.opacity(0.5), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    func summaryPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(design.accentColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(design.accentColor.opacity(0.12))
        .clipShape(Capsule())
    }

    func summaryStatTile(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.16))
                    .clipShape(Circle())
            }

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(design.textColor)

            Text(subtitle)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.md)
        .streetBeastSurface()
    }

    var planDisplayName: String {
        if let key = session.plan.nameKey {
            return localization.localized(key)
        }
        return session.plan.name
    }

    var exerciseSteps: [TrainingStep] {
        session.plan.steps.filter { $0.kind == .exercise }
    }

    var restSummary: String? {
        let restSteps = session.plan.steps.filter { $0.kind == .rest }
        guard !restSteps.isEmpty else { return nil }

        let durations = restSteps.map { $0.durationSeconds }
        let uniqueDurations = Set(durations)
        if uniqueDurations.count == 1, let duration = uniqueDurations.first {
            return String(format: localization.localized("training_plan_rest_summary_format"), restSteps.count, shortDuration(duration))
        }

        let total = restSteps.reduce(0) { $0 + max($1.durationSeconds, 0) }
        return String(format: localization.localized("training_plan_rest_summary_total_format"), restSteps.count, shortDuration(total))
    }

    func formattedDuration(_ seconds: Int) -> String {
        let clamped = max(seconds, 0)
        let minutes = clamped / 60
        let remainder = clamped % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    func shortDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return String(format: localization.localized("timer_seconds_format"), seconds)
        }
        return formattedDuration(seconds)
    }
}

#Preview {
    WorkoutSummaryView(
        session: WorkoutSession(
            plan: TrainingPlan.builtIns.first ?? TrainingPlan(name: "Workout", prepareSeconds: 10, steps: []),
            startedAt: Date().addingTimeInterval(-1200),
            completedAt: Date()
        ),
        onDone: {},
        onRestart: {}
    )
}
