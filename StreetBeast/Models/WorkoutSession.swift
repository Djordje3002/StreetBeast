import Foundation

struct WorkoutSession: Identifiable, Codable, Equatable {
    var id: UUID
    var plan: TrainingPlan
    var startedAt: Date
    var completedAt: Date
    var totalDurationSeconds: Int
    var workDurationSeconds: Int
    var restDurationSeconds: Int
    var totalSteps: Int
    var workSteps: Int
    var restSteps: Int

    init(id: UUID = UUID(), plan: TrainingPlan, startedAt: Date, completedAt: Date) {
        let normalizedPlan = plan.normalized()
        self.id = id
        self.plan = normalizedPlan
        self.startedAt = startedAt
        self.completedAt = completedAt

        let workSteps = normalizedPlan.steps.filter { $0.kind == .exercise }
        let restSteps = normalizedPlan.steps.filter { $0.kind == .rest }

        self.workSteps = workSteps.reduce(0) { $0 + max($1.repeatCount, 1) }
        self.restSteps = restSteps.reduce(0) { $0 + max($1.repeatCount, 1) }
        self.totalSteps = normalizedPlan.totalStepInstances
        self.workDurationSeconds = workSteps.reduce(0) { total, step in
            total + (max(step.durationSeconds, 0) * max(step.repeatCount, 1))
        }
        self.restDurationSeconds = restSteps.reduce(0) { total, step in
            total + (max(step.durationSeconds, 0) * max(step.repeatCount, 1))
        }
        self.totalDurationSeconds = max(normalizedPlan.prepareSeconds, 0) + workDurationSeconds + restDurationSeconds
    }
}
