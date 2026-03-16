import SwiftUI

struct ExercisesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    private let exercises = Exercise.library

    var body: some View {
        NavigationStack {
            ZStack {
                StreetBeastBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        headerCopy

                        ForEach(exercises) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                ExerciseRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.lg)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle(localization.localized("exercises_title"))
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

    private var headerCopy: some View {
        Text(localization.localized("exercises_subtitle"))
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(design.secondaryTextColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ExerciseImageView(exercise: exercise, size: CGSize(width: 96, height: 96))

            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)

                Text(metadataText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(design.secondaryTextColor)
            }

            Spacer()

            HStack(spacing: 6) {
                Text(localization.localized("exercise_view_more"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(design.accentColor)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(design.accentColor)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .streetBeastSurface()
    }

    private var metadataText: String {
        let category = localization.localized(exercise.category.titleKey)
        let difficulty = localization.localized(exercise.difficulty.titleKey)
        let equipment = equipmentText
        return "\(category) • \(difficulty) • \(equipment)"
    }

    private var equipmentText: String {
        let equipmentNames = exercise.equipment.map { localization.localized($0.titleKey) }
        return equipmentNames.joined(separator: ", ")
    }

    private var categoryColor: Color {
        switch exercise.category {
        case .pull: return design.accentColor
        case .push: return design.flameColor
        case .triceps: return design.candleColor
        case .legs: return design.accentColor.opacity(0.8)
        case .core: return design.flameColor.opacity(0.8)
        case .conditioning: return design.candleColor.opacity(0.9)
        }
    }
}

private struct ExerciseDetailView: View {
    let exercise: Exercise

    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        ZStack {
            StreetBeastBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    ExerciseImageView(exercise: exercise, size: CGSize(width: 260, height: 260))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(design.textColor)

                        Text(localization.localized(exercise.category.titleKey))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(design.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    detailCard

                    descriptionCard
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.lg)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle(localization.localized("exercises_detail_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailCard: some View {
        SettingsCardGroup {
            SettingsListRow(icon: "tag.fill", title: localization.localized("exercise_category_label")) {
                Text(localization.localized(exercise.category.titleKey))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)
            }

            SettingsRowDivider()

            SettingsListRow(icon: "speedometer", title: localization.localized("exercise_difficulty_label")) {
                Text(localization.localized(exercise.difficulty.titleKey))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)
            }

            SettingsRowDivider()

            SettingsListRow(icon: "figure.strengthtraining.traditional", title: localization.localized("exercise_equipment_label")) {
                Text(equipmentText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(design.textColor)
            }
        }
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localization.localized("exercise_description_label"))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(design.textColor)

            Text(exercise.description)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(design.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.lg)
        .streetBeastSurface()
    }

    private var equipmentText: String {
        let equipmentNames = exercise.equipment.map { localization.localized($0.titleKey) }
        return equipmentNames.joined(separator: ", ")
    }
}

private struct ExerciseImageView: View {
    let exercise: Exercise
    let size: CGSize

    @ObservedObject private var design = DesignSystem.shared

    private var placeholderIcon: String {
        switch exercise.category {
        case .pull:          return "figure.pull.up"
        case .push:          return "figure.push.up"
        case .triceps:       return "dumbbell.fill"
        case .legs:          return "figure.run"
        case .core:          return "figure.core.training"
        case .conditioning:  return "flame.fill"
        }
    }

    private var placeholderLabel: String {
        switch exercise.category {
        case .pull:          return "Pull"
        case .push:          return "Push"
        case .triceps:       return "Triceps"
        case .legs:          return "Legs"
        case .core:          return "Core"
        case .conditioning:  return "Cardio"
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(design.paperColor.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(design.accentColor.opacity(0.15), lineWidth: 1)
                )

            if let uiImage = UIImage(named: exercise.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 6) {
                    Image(systemName: placeholderIcon)
                        .font(.system(size: size.height < 100 ? 24 : 42, weight: .semibold))
                        .foregroundColor(design.accentColor.opacity(0.85))
                    if size.height >= 100 {
                        Text(placeholderLabel)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(design.secondaryTextColor)
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    ExercisesView()
}
