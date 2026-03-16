import SwiftUI

struct StrengthEditView: View {
    @ObservedObject private var design = DesignSystem.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var store = MaxStrengthStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var draft: MaxStrength

    init() {
        _draft = State(initialValue: MaxStrengthStore.shared.current)
    }

    var body: some View {
        ScreenScaffold(
            contentTopPadding: 120,
            horizontalPadding: DesignSystem.Spacing.lg,
            bottomPadding: 140,
            header: {
                header
            },
            content: {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Text(localization.localized("progress_strength_edit_subtitle"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(design.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    strengthSlider(
                        title: localization.localized("onboarding_strength_pullups"),
                        keyPath: \.pullUps,
                        range: StrengthRange.pullUps
                    )
                    strengthSlider(
                        title: localization.localized("onboarding_strength_pushups"),
                        keyPath: \.pushUps,
                        range: StrengthRange.pushUps
                    )
                    strengthSlider(
                        title: localization.localized("onboarding_strength_dips"),
                        keyPath: \.dips,
                        range: StrengthRange.dips
                    )
                    strengthSlider(
                        title: localization.localized("onboarding_strength_muscleups"),
                        keyPath: \.muscleUps,
                        range: StrengthRange.muscleUps
                    )

                    PrimaryActionButton(
                        title: localization.localized("progress_strength_save"),
                        action: save
                    )
                    .padding(.top, DesignSystem.Spacing.sm)
                }
            }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .dynamicTypeSize(.medium ... .accessibility3)
    }

    private var header: some View {
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

                Text(localization.localized("progress_strength_edit_title"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(design.textColor)

                Spacer()
            }
        }
    }

    private func save() {
        store.update(draft)
        Task {
            if let uid = AuthManager.shared.currentUser?.id {
                do {
                    try await AuthService.shared.updateMaxStrength(draft, for: uid)
                    MaxStrengthSyncService.shared.clearPending()
                } catch {
                    MaxStrengthSyncService.shared.enqueue(draft)
                }
            } else {
                MaxStrengthSyncService.shared.enqueue(draft)
            }
        }
        dismiss()
    }

    private func strengthSlider(
        title: String,
        keyPath: WritableKeyPath<MaxStrength, Int>,
        range: ClosedRange<Int>
    ) -> some View {
        let value = draft[keyPath: keyPath]

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(design.secondaryTextColor)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                strengthValueBadge(value: value)
            }

            StrengthSlider(
                value: intBinding(keyPath),
                range: range,
                title: title,
                repLabel: localization.localized("leaderboard_reps_label"),
                accentColor: design.accentColor,
                trackColor: design.secondaryTextColor
            )

            HStack {
                Text("\(range.lowerBound)")
                Spacer()
                Text("\(range.upperBound)")
            }
            .font(DesignSystem.Typography.referenceSmall)
            .foregroundColor(design.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.md)
        .streetBeastSurface()
    }

    private func strengthValueBadge(value: Int) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(design.textColor)

            Text(localization.localized("leaderboard_reps_label"))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(design.secondaryTextColor)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(design.accentColor.opacity(0.12))
        .overlay(
            Capsule()
                .stroke(design.accentColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private func intBinding(_ keyPath: WritableKeyPath<MaxStrength, Int>) -> Binding<Int> {
        Binding(
            get: { draft[keyPath: keyPath] },
            set: { draft[keyPath: keyPath] = $0 }
        )
    }

    private enum StrengthRange {
        static let pullUps: ClosedRange<Int> = 0...40
        static let pushUps: ClosedRange<Int> = 0...200
        static let dips: ClosedRange<Int> = 0...100
        static let muscleUps: ClosedRange<Int> = 0...25
    }
}

private struct StrengthSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let title: String
    let repLabel: String
    let accentColor: Color
    let trackColor: Color

    var body: some View {
        GeometryReader { geo in
            let width = max(1, geo.size.width)
            let clampedValue = min(max(value, range.lowerBound), range.upperBound)
            let normalized = CGFloat(clampedValue - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound)
            let knobSize: CGFloat = 22
            let trackHeight: CGFloat = 6
            let knobOffset = (width * normalized) - (knobSize / 2)
            let clampedOffset = min(max(0, knobOffset), width - knobSize)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor.opacity(0.18))
                    .frame(height: trackHeight)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.65)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(trackHeight, width * normalized), height: trackHeight)

                Circle()
                    .fill(accentColor)
                    .frame(width: knobSize, height: knobSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.9), lineWidth: 2)
                    )
                    .shadow(color: accentColor.opacity(0.35), radius: 4, x: 0, y: 2)
                    .offset(x: clampedOffset, y: -(knobSize - trackHeight) / 2)
            }
            .frame(height: knobSize)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let location = min(max(0, gesture.location.x), width)
                        let percent = location / width
                        let rawValue = (percent * CGFloat(range.upperBound - range.lowerBound)) + CGFloat(range.lowerBound)
                        value = Int(rawValue.rounded())
                    }
            )
        }
        .frame(height: 28)
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityValue("\(value) \(repLabel)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(value + 1, range.upperBound)
            case .decrement:
                value = max(value - 1, range.lowerBound)
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    StrengthEditView()
}
