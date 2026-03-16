import Foundation

struct Exercise: Identifiable, Equatable {
    let id: String
    let name: String
    let imageName: String
    let category: ExerciseCategory
    let difficulty: ExerciseDifficulty
    let equipment: [ExerciseEquipment]
    let description: String

    init(
        name: String,
        imageName: String,
        category: ExerciseCategory,
        difficulty: ExerciseDifficulty,
        equipment: [ExerciseEquipment],
        description: String
    ) {
        self.id = name
        self.name = name
        self.imageName = imageName
        self.category = category
        self.difficulty = difficulty
        self.equipment = equipment
        self.description = description
    }
}

enum ExerciseCategory: String, CaseIterable {
    case pull
    case push
    case triceps
    case legs
    case core
    case conditioning

    var titleKey: String {
        switch self {
        case .pull: return "exercise_category_pull"
        case .push: return "exercise_category_push"
        case .triceps: return "exercise_category_triceps"
        case .legs: return "exercise_category_legs"
        case .core: return "exercise_category_core"
        case .conditioning: return "exercise_category_conditioning"
        }
    }
}

enum ExerciseDifficulty: String, CaseIterable {
    case easy
    case medium
    case hard

    var titleKey: String {
        switch self {
        case .easy: return "exercise_difficulty_easy"
        case .medium: return "exercise_difficulty_medium"
        case .hard: return "exercise_difficulty_hard"
        }
    }
}

enum ExerciseEquipment: String, CaseIterable {
    case none
    case floor
    case bar
    case pullUpBar
    case parallelBars
    case bench

    var titleKey: String {
        switch self {
        case .none: return "exercise_equipment_none"
        case .floor: return "exercise_equipment_floor"
        case .bar: return "exercise_equipment_bar"
        case .pullUpBar: return "exercise_equipment_pullup_bar"
        case .parallelBars: return "exercise_equipment_parallel_bars"
        case .bench: return "exercise_equipment_bench"
        }
    }
}

extension Exercise {
    static let library: [Exercise] = [
        Exercise(
            name: "Pull-ups",
            imageName: "ex_pullups",
            category: .pull,
            difficulty: .hard,
            equipment: [.pullUpBar],
            description: "Classic overhand grip pull. Drive elbows down, keep chest up, and control the descent."
        ),
        Exercise(
            name: "Chin-ups",
            imageName: "ex_chinups",
            category: .pull,
            difficulty: .medium,
            equipment: [.pullUpBar],
            description: "Underhand grip pull with more biceps emphasis. Keep shoulders packed and avoid swinging."
        ),
        Exercise(
            name: "Neutral Grip Pull-ups",
            imageName: "ex_neutral_pullups",
            category: .pull,
            difficulty: .medium,
            equipment: [.pullUpBar],
            description: "Palms facing each other to reduce shoulder strain. Focus on smooth, controlled reps."
        ),
        Exercise(
            name: "Australian Pull-ups (Inverted Rows)",
            imageName: "ex_australian_pullups",
            category: .pull,
            difficulty: .easy,
            equipment: [.bar],
            description: "Bodyweight row under a bar. Keep a straight line and pull your chest to the bar."
        ),
        Exercise(
            name: "Muscle-ups",
            imageName: "ex_muscleups",
            category: .pull,
            difficulty: .hard,
            equipment: [.pullUpBar],
            description: "Explosive pull that transitions into a dip. Requires strong pull and fast turnover."
        ),
        Exercise(
            name: "Pushups",
            imageName: "ex_pushups",
            category: .push,
            difficulty: .easy,
            equipment: [.floor],
            description: "Standard bodyweight press. Keep core tight, elbows at ~45°, and full range of motion."
        ),
        Exercise(
            name: "Decline Pushups",
            imageName: "ex_decline_pushups",
            category: .push,
            difficulty: .medium,
            equipment: [.bench],
            description: "Feet elevated to target upper chest and shoulders. Maintain a straight body line."
        ),
        Exercise(
            name: "Diamond Pushups",
            imageName: "ex_diamond_pushups",
            category: .push,
            difficulty: .medium,
            equipment: [.floor],
            description: "Close-hand pushup that loads triceps and inner chest. Keep shoulders stacked."
        ),
        Exercise(
            name: "Dips",
            imageName: "ex_dips",
            category: .push,
            difficulty: .hard,
            equipment: [.parallelBars],
            description: "Parallel bar push. Lean slightly forward for chest or stay upright for triceps focus."
        ),
        Exercise(
            name: "Bar Pushups (Incline Pushups)",
            imageName: "ex_incline_pushups",
            category: .push,
            difficulty: .easy,
            equipment: [.bar],
            description: "Pushups with hands elevated on a bar or bench. Easier angle, great for volume."
        ),
        Exercise(
            name: "Bodyweight Tricep Extensions (Skull Crushers)",
            imageName: "ex_tricep_extensions",
            category: .triceps,
            difficulty: .medium,
            equipment: [.bar],
            description: "Also called bodyweight tricep extensions. Lean forward on a bar/bench and extend the elbows."
        ),
        Exercise(
            name: "Squats",
            imageName: "ex_squats",
            category: .legs,
            difficulty: .easy,
            equipment: [.none],
            description: "Basic bodyweight squat. Sit hips back, keep knees tracking over toes."
        ),
        Exercise(
            name: "Calf Raises",
            imageName: "ex_calf_raises",
            category: .legs,
            difficulty: .easy,
            equipment: [.none],
            description: "Rise onto the balls of your feet, pause at the top, and lower with control."
        ),
        Exercise(
            name: "Jump Squats",
            imageName: "ex_jump_squats",
            category: .legs,
            difficulty: .medium,
            equipment: [.none],
            description: "Explosive squat variation. Land softly and keep your core tight."
        ),
        Exercise(
            name: "Bulgarian Split Squats",
            imageName: "ex_bulgarian_split_squats",
            category: .legs,
            difficulty: .hard,
            equipment: [.bench],
            description: "Single-leg squat with rear foot elevated. Keep front knee stable and chest tall."
        ),
        Exercise(
            name: "Hanging Knee Raises",
            imageName: "ex_hanging_knee_raises",
            category: .core,
            difficulty: .medium,
            equipment: [.pullUpBar],
            description: "Raise knees toward chest while hanging. Avoid swinging and control the lowering phase."
        ),
        Exercise(
            name: "Hanging Leg Raises",
            imageName: "ex_hanging_leg_raises",
            category: .core,
            difficulty: .hard,
            equipment: [.pullUpBar],
            description: "Straight-leg version of knee raises. Keep legs together and core braced."
        ),
        Exercise(
            name: "Plank",
            imageName: "ex_plank",
            category: .core,
            difficulty: .easy,
            equipment: [.floor],
            description: "Static core hold. Keep a straight line from head to heels and breathe steadily."
        ),
        Exercise(
            name: "Burpees",
            imageName: "ex_burpees",
            category: .conditioning,
            difficulty: .hard,
            equipment: [.floor],
            description: "Full-body conditioning: squat → pushup → jump. Keep pace and land softly."
        )
    ]
}
