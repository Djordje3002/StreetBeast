import SwiftUI

struct ProgressHubView: View {
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var maxStrengthStore = MaxStrengthStore.shared
    @StateObject private var workoutStore = WorkoutSessionStore.shared
    @ObservedObject private var authManager = AuthManager.shared

    private var strengthStats: [(key: String, value: Int, icon: String)] {
        [
            ("progress_pullups_label", maxStrengthStore.current.pullUps, "figure.pullup"),
            ("progress_pushups_label", maxStrengthStore.current.pushUps, "figure.pushup"),
            ("progress_dips_label", maxStrengthStore.current.dips, "figure.strengthtraining.traditional"),
            ("progress_muscleups_label", maxStrengthStore.current.muscleUps, "flame.fill")
        ]
    }

    var body: some View {
        ScreenScaffold(
            contentTopPadding: 120,
            horizontalPadding: DesignSystem.Spacing.lg,
            bottomPadding: 140,
            header: {
                EmptyView()
            },
            content: {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    xpSection
                    strengthSection
                    predictionSection
                    volumeSection
                    trainingLibrarySection
                }
            }
        )
        .dynamicTypeSize(.medium ... .accessibility3)
        .task {
            if let uid = authManager.currentUser?.id {
                await workoutStore.refreshFromRemote(uid: uid)
            }
        }
    }
}

// MARK: - Sections
private extension ProgressHubView {
    var xpSection: some View {
        SectionBlock(title: localization.localized("progress_xp_title")) {
            VStack(spacing: DesignSystem.Spacing.md) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.md) {
                    StatCard(
                        title: localization.localized("progress_xp_total_title"),
                        value: String(totalXP),
                        subtitle: localization.localized("progress_xp_total_subtitle"),
                        icon: "bolt.fill",
                        color: design.accentColor
                    )

                    StatCard(
                        title: localization.localized("progress_level_title"),
                        value: String(levelInfo.level),
                        subtitle: localization.localized("progress_level_subtitle"),
                        icon: "star.fill",
                        color: design.flameColor
                    )
                }

                progressGraphCard(
                    title: localization.localized("progress_xp_graph_title"),
                    subtitle: localization.localized("progress_xp_graph_subtitle"),
                    accent: design.accentColor,
                    values: xpTrend
                )
            }
        }
    }

    var strengthSection: some View {
        SectionBlock(title: localization.localized("progress_strength_title")) {
            NavigationLink {
                StrengthEditView()
            } label: {
                VStack(spacing: DesignSystem.Spacing.md) {
                    SettingsCardGroup {
                        ForEach(Array(strengthStats.enumerated()), id: \.offset) { index, stat in
                            SettingsListRow(icon: stat.icon, title: localization.localized(stat.key)) {
                                Text(String(format: localization.localized("progress_reps_format"), stat.value))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(design.textColor)
                            }

                            if index < strengthStats.count - 1 {
                                SettingsRowDivider()
                            }
                        }
                    }

                    Text(localization.localized("progress_strength_subtitle"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(design.secondaryTextColor)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                }
            }
            .buttonStyle(.plain)
        }
    }

    var predictionSection: some View {
        SectionBlock(title: localization.localized("progress_prediction_title")) {
            NavigationSurfaceCard(
                spacing: DesignSystem.Spacing.md,
                horizontalPadding: DesignSystem.Spacing.lg,
                verticalPadding: DesignSystem.Spacing.lg,
                showChevron: false,
                leading: {
                    Circle()
                        .fill(design.accentColor.opacity(0.18))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(design.accentColor)
                        )
                },
                content: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.localized("progress_prediction_headline"))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(design.textColor)

                        Text(localization.localized("progress_prediction_text"))
                            .font(.system(size: 14))
                            .foregroundColor(design.secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            )
        }
    }

    var volumeSection: some View {
        SectionBlock(title: localization.localized("progress_volume_title")) {
            progressGraphCard(
                title: localization.localized("progress_volume_graph_title"),
                subtitle: localization.localized("progress_volume_graph_subtitle"),
                accent: design.candleColor,
                values: volumeTrend
            )
        }
    }

    var trainingLibrarySection: some View {
        SectionBlock(title: localization.localized("progress_training_title")) {
            SettingsCardGroup {
                ForEach(trainingOptions, id: \.id) { option in
                    SettingsListRow(icon: option.icon, title: localization.localized(option.titleKey)) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(design.secondaryTextColor)
                    }

                    if option.id != trainingOptions.last?.id {
                        SettingsRowDivider()
                    }
                }
            }
        }
    }
}

// MARK: - Cards
private extension ProgressHubView {
    func progressGraphCard(title: String, subtitle: String, accent: Color, values: [Double]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(design.textColor)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(design.secondaryTextColor)
                }

                Spacer()

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accent)
                    .padding(8)
                    .background(accent.opacity(0.12))
                    .clipShape(Circle())
            }

            LineGraph(values: values, accent: accent)
                .frame(height: 140)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.lg)
        .streetBeastSurface()
    }

    var xpTrend: [Double] {
        workoutStore.weeklyXPSeries(weeks: 7)
    }

    var volumeTrend: [Double] {
        workoutStore.weeklyVolumeSeries(weeks: 7)
    }

    var totalXP: Int {
        workoutStore.totalXP
    }

    var levelInfo: XPLeveling.LevelInfo {
        workoutStore.levelInfo
    }

    struct TrainingOption: Identifiable {
        let id: String
        let titleKey: String
        let icon: String
    }

    var trainingOptions: [TrainingOption] {
        [
            TrainingOption(id: "beginner", titleKey: "home_workout_beginner", icon: "leaf.fill"),
            TrainingOption(id: "strength", titleKey: "home_workout_strength", icon: "bolt.fill"),
            TrainingOption(id: "endurance", titleKey: "home_workout_endurance", icon: "flame.fill"),
            TrainingOption(id: "custom", titleKey: "home_workout_custom", icon: "slider.horizontal.3")
        ]
    }
}

private struct LineGraph: View {
    let values: [Double]
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            let points = normalizedPoints(in: geo.size)

            ZStack {
                graphGrid(in: geo.size)

                if points.count > 1 {
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: points.last?.x ?? 0, y: geo.size.height))
                        path.addLine(to: CGPoint(x: points.first?.x ?? 0, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.28), accent.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .shadow(color: accent.opacity(0.2), radius: 6, x: 0, y: 4)
                }

                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(accent)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                        )
                        .position(point)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = max(maxValue - minValue, 1)

        return values.enumerated().map { index, value in
            let x = size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
            let yRatio = CGFloat((value - minValue) / range)
            let y = size.height - (yRatio * size.height)
            return CGPoint(x: x, y: y)
        }
    }

    private func graphGrid(in size: CGSize) -> some View {
        let lines = 3
        return ForEach(0..<lines, id: \.self) { index in
            let y = size.height * CGFloat(index) / CGFloat(lines - 1)
            Path { path in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            .stroke(accent.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
        }
    }
}

#Preview {
    ProgressHubView()
}
