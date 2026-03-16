import Foundation

enum TrainingStepKind: String, Codable, CaseIterable {
    case exercise
    case rest
}

struct TrainingStep: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: TrainingStepKind
    var exerciseId: String?
    var exerciseName: String
    var durationSeconds: Int
    var repeatCount: Int

    init(
        id: UUID = UUID(),
        kind: TrainingStepKind,
        exercise: Exercise? = nil,
        exerciseName: String = "",
        durationSeconds: Int,
        repeatCount: Int = 1
    ) {
        self.id = id
        self.kind = kind
        self.exerciseId = exercise?.id
        self.exerciseName = exercise?.name ?? exerciseName
        self.durationSeconds = durationSeconds
        self.repeatCount = repeatCount
    }

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case exerciseId
        case exerciseName
        case durationSeconds
        case repeatCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(TrainingStepKind.self, forKey: .kind)
        exerciseId = try container.decodeIfPresent(String.self, forKey: .exerciseId)
        exerciseName = try container.decode(String.self, forKey: .exerciseName)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        repeatCount = try container.decodeIfPresent(Int.self, forKey: .repeatCount) ?? 1
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(exerciseId, forKey: .exerciseId)
        try container.encode(exerciseName, forKey: .exerciseName)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(repeatCount, forKey: .repeatCount)
    }
}

struct TrainingPlan: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var nameKey: String?
    var prepareSeconds: Int
    var steps: [TrainingStep]

    init(
        id: UUID = UUID(),
        name: String,
        nameKey: String? = nil,
        prepareSeconds: Int,
        steps: [TrainingStep]
    ) {
        self.id = id
        self.name = name
        self.nameKey = nameKey
        self.prepareSeconds = prepareSeconds
        self.steps = steps
    }

    var totalDurationSeconds: Int {
        let stepsTotal = steps.reduce(0) { total, step in
            let repeats = max(step.repeatCount, 1)
            return total + (max(step.durationSeconds, 0) * repeats)
        }
        return max(prepareSeconds, 0) + stepsTotal
    }

    var totalStepInstances: Int {
        steps.reduce(0) { $0 + max($1.repeatCount, 1) }
    }

    func normalized() -> TrainingPlan {
        var normalizedSteps: [TrainingStep] = []
        for step in steps {
            let trimmedName = step.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
            if step.kind == .exercise && trimmedName.isEmpty {
                continue
            }

            var sanitized = step
            sanitized.durationSeconds = max(5, step.durationSeconds)
            if step.kind == .rest {
                sanitized.repeatCount = 1
            } else {
                sanitized.repeatCount = min(max(step.repeatCount, 1), 20)
            }
            normalizedSteps.append(sanitized)
        }

        return TrainingPlan(
            id: id,
            name: name,
            nameKey: nameKey,
            prepareSeconds: max(0, prepareSeconds),
            steps: normalizedSteps
        )
    }
}

extension TrainingPlan {
    private static func exerciseStep(_ name: String, seconds: Int, repeats: Int = 1) -> TrainingStep {
        let exercise = Exercise.library.first { $0.name == name }
        return TrainingStep(kind: .exercise, exercise: exercise, exerciseName: name, durationSeconds: seconds, repeatCount: repeats)
    }

    private static func restStep(_ seconds: Int) -> TrainingStep {
        TrainingStep(kind: .rest, exerciseName: "", durationSeconds: seconds, repeatCount: 1)
    }

    static let builtIns: [TrainingPlan] = [
        TrainingPlan(
            name: "Pull Strength 40",
            nameKey: "home_workout_pull_40",
            prepareSeconds: 0,
            steps: [
                exerciseStep("Pull-ups", seconds: 60, repeats: 8),
                exerciseStep("Neutral Grip Pull-ups", seconds: 60, repeats: 8),
                exerciseStep("Chin-ups", seconds: 60, repeats: 8),
                exerciseStep("Australian Pull-ups (Inverted Rows)", seconds: 60, repeats: 8),
                exerciseStep("Hanging Knee Raises", seconds: 60, repeats: 4),
                exerciseStep("Hanging Leg Raises", seconds: 60, repeats: 4)
            ]
        ),
        TrainingPlan(
            name: "Push Strength 40",
            nameKey: "home_workout_push_40",
            prepareSeconds: 0,
            steps: [
                exerciseStep("Pushups", seconds: 60, repeats: 8),
                exerciseStep("Decline Pushups", seconds: 60, repeats: 8),
                exerciseStep("Dips", seconds: 60, repeats: 8),
                exerciseStep("Diamond Pushups", seconds: 60, repeats: 8),
                exerciseStep("Bar Pushups (Incline Pushups)", seconds: 60, repeats: 4),
                exerciseStep("Bodyweight Tricep Extensions (Skull Crushers)", seconds: 60, repeats: 4)
            ]
        ),
        TrainingPlan(
            name: "Beginner Workout",
            nameKey: "home_workout_beginner",
            prepareSeconds: 10,
            steps: [
                exerciseStep("Pushups", seconds: 45),
                restStep(20),
                exerciseStep("Squats", seconds: 60),
                restStep(20),
                exerciseStep("Plank", seconds: 45),
                restStep(20),
                exerciseStep("Bar Pushups (Incline Pushups)", seconds: 45)
            ]
        ),
        TrainingPlan(
            name: "Strength Builder",
            nameKey: "home_workout_strength",
            prepareSeconds: 10,
            steps: [
                exerciseStep("Pull-ups", seconds: 60),
                restStep(30),
                exerciseStep("Dips", seconds: 60),
                restStep(30),
                exerciseStep("Pushups", seconds: 60),
                restStep(30),
                exerciseStep("Squats", seconds: 60)
            ]
        ),
        TrainingPlan(
            name: "Endurance Circuit",
            nameKey: "home_workout_endurance",
            prepareSeconds: 10,
            steps: [
                exerciseStep("Burpees", seconds: 45),
                restStep(15),
                exerciseStep("Jump Squats", seconds: 45),
                restStep(15),
                exerciseStep("Pushups", seconds: 45),
                restStep(15),
                exerciseStep("Plank", seconds: 45)
            ]
        )
    ]
}
