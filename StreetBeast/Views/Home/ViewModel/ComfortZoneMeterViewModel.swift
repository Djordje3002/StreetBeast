import SwiftUI
import Combine

@MainActor
final class ComfortZoneMeterViewModel: ObservableObject {
    @Published private(set) var model: ComfortZoneMeterModel
    @Published private(set) var animatedOuterScore: Double
    @Published private(set) var animatedMiddleScore: Double
    @Published private(set) var animatedInnerScore: Double

    private var didAnimateOnAppear = false

    init(scoresByRange: [MeterRange: Double]) {
        let initialModel = ComfortZoneMeterModel(scoresByRange: scoresByRange)
        self.model = initialModel
        self.animatedOuterScore = 0
        self.animatedMiddleScore = 0
        self.animatedInnerScore = 0
    }

    func onAppear() {
        guard !didAnimateOnAppear else { return }
        didAnimateOnAppear = true
        animateToModel()
    }

    func update(scoresByRange: [MeterRange: Double]) {
        model = ComfortZoneMeterModel(scoresByRange: scoresByRange)
        animateToModel()
    }

    private func animateToModel() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) {
            animatedOuterScore = model.monthScore
            animatedMiddleScore = model.weekScore
            animatedInnerScore = model.dayScore
        }
    }
}
