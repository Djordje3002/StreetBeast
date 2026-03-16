import SwiftUI

struct ComfortZoneMeter: View {
    let scoresByRange: [MeterRange: Double]
    @ObservedObject var design = DesignSystem.shared
    @ObservedObject var localization = LocalizationManager.shared
    @StateObject private var viewModel: ComfortZoneMeterViewModel

    private var outerColor: Color { bandColor(.grow) }
    private var middleColor: Color { bandColor(.learning) }
    private var innerColor: Color { bandColor(.home) }

    init(scoresByRange: [MeterRange: Double]) {
        self.scoresByRange = scoresByRange
        _viewModel = StateObject(wrappedValue: ComfortZoneMeterViewModel(scoresByRange: scoresByRange))
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            compactRingStack
            zoneCardsRow
        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .streetBeastSurface()
        .neonShadow(color: design.accentColor.opacity(0.16), radius: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(
                format: localization.localized("comfort_zone_accessibility"),
                viewModel.model.scorePercent,
                localization.localized(viewModel.model.activeBand.zoneKey)
            )
        )
        .onAppear(perform: viewModel.onAppear)
        .onChange(of: scoresByRange) { _, newScores in
            viewModel.update(scoresByRange: newScores)
        }
    }

    private var compactRingStack: some View {
        ZStack {
            ringLayer(
                diameter: 240,
                lineWidth: 24,
                progress: viewModel.animatedOuterScore,
                color: outerColor,
                symbol: ComfortZoneBand.grow.symbol
            )

            ringLayer(
                diameter: 186,
                lineWidth: 22,
                progress: viewModel.animatedMiddleScore,
                color: middleColor,
                symbol: ComfortZoneBand.learning.symbol
            )

            ringLayer(
                diameter: 134,
                lineWidth: 20,
                progress: viewModel.animatedInnerScore,
                color: innerColor,
                symbol: ComfortZoneBand.home.symbol
            )

            Circle()
                .fill(design.backgroundColor)
                .frame(width: 76, height: 76)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .padding(.bottom, 12)
    }

    private var zoneCardsRow: some View {
        HStack(spacing: 8) {
            ForEach(ComfortZoneBand.allCases, id: \.self) { band in
                zoneCard(for: band)
            }
        }
        .padding(.top, 6)
    }

    private func zoneCard(for band: ComfortZoneBand) -> some View {
        let isActive = band == viewModel.model.activeBand
        let bandColor = band.color(with: design)

        return VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: band.symbol)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(design.textColor)

                Text(band.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(design.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(band.rangeText)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(design.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(bandColor.opacity(isActive ? 0.34 : 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(bandColor.opacity(isActive ? 0.8 : 0.35), lineWidth: isActive ? 1.4 : 1)
                )
        )
    }

    private func ringLayer(
        diameter: CGFloat,
        lineWidth: CGFloat,
        progress: Double,
        color: Color,
        symbol: String
    ) -> some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.16),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(128))

            ringBadge(symbol: symbol, color: color, radius: diameter / 2)
        }
        .frame(width: diameter, height: diameter)
    }

    private func ringBadge(symbol: String, color: Color, radius: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(design.backgroundColor)
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.35), lineWidth: 1)
                )

            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: 24, height: 24)
        .offset(y: -radius)
    }

    private func bandColor(_ band: ComfortZoneBand) -> Color {
        switch band {
        case .home:
            return design.accentColor
        case .learning:
            return design.candleColor
        case .grow:
            return design.flameColor
        }
    }
}

private extension ComfortZoneBand {
    func color(with design: DesignSystem) -> Color {
        switch self {
        case .home:
            return design.accentColor
        case .learning:
            return design.candleColor
        case .grow:
            return design.flameColor
        }
    }
}

#Preview {
    ComfortZoneMeter(
        scoresByRange: [
            .day24H: 0.28,
            .week7D: 0.41,
            .month1M: 0.67,
            .month3M: 0.62,
            .year1Y: 0.58,
            .custom: 0.58
        ]
    )
    .padding()
    .background(DesignSystem.shared.backgroundColor)
}
