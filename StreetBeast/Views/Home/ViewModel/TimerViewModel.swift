import SwiftUI
import Combine
import AVFoundation

enum TimerPhase: String {
    case prepare
    case work
    case rest
    case complete

    var titleKey: String {
        switch self {
        case .prepare: return "timer_phase_prepare"
        case .work: return "timer_phase_work"
        case .rest: return "timer_phase_rest"
        case .complete: return "timer_phase_complete"
        }
    }
}

@MainActor
class TimerViewModel: ObservableObject {
    @Published private(set) var currentPhase: TimerPhase = .prepare
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var currentStepIndex: Int = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var hasStarted: Bool = false
    @Published private(set) var isCompleted: Bool = false
    @Published private(set) var selectedPlan: TrainingPlan
    @Published private(set) var lastCompletedSession: WorkoutSession?

    private var timer: Timer?
    private var sessionStartedAt: Date?
    private var expandedSteps: [ExpandedStep] = []

    init(plan: TrainingPlan? = nil) {
        let defaultPlan = TrainingPlan.builtIns.first(where: { !Self.isBeginnerPlan($0) })
            ?? TrainingPlan.builtIns.first
            ?? TrainingPlan(name: "Workout", prepareSeconds: 0, steps: [])
        let effectivePlan = plan ?? defaultPlan
        self.selectedPlan = effectivePlan.normalized()
        rebuildExpandedSteps()
        reset()
    }

    private static func isBeginnerPlan(_ plan: TrainingPlan) -> Bool {
        if plan.nameKey == "home_workout_beginner" { return true }
        return plan.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "beginner workout"
    }

    deinit {
        timer?.invalidate()
    }

    var currentPhaseDuration: Int {
        switch currentPhase {
        case .prepare:
            return selectedPlan.prepareSeconds
        case .work, .rest:
            return currentStep?.durationSeconds ?? 0
        case .complete: return 0
        }
    }

    var totalTimeSeconds: Int {
        selectedPlan.totalDurationSeconds
    }

    var phaseProgress: Double {
        if currentPhase == .complete { return 1 }
        let duration = max(currentPhaseDuration, 1)
        return 1 - (Double(max(remainingSeconds, 0)) / Double(duration))
    }

    var stepProgress: Double {
        guard totalSteps > 0 else { return 0 }
        if isCompleted { return 1 }
        if currentPhase == .prepare { return 0 }
        let base = Double(max(currentStepIndex, 0)) / Double(totalSteps)
        let extra = phaseProgress / Double(totalSteps)
        return min(1, base + extra)
    }

    var planProgress: Double {
        let total = max(totalTimeSeconds, 1)
        let elapsed = elapsedSeconds
        return min(1, Double(elapsed) / Double(total))
    }

    var totalSteps: Int {
        expandedSteps.count
    }

    var currentStep: TrainingStep? {
        guard expandedSteps.indices.contains(currentStepIndex) else { return nil }
        return expandedSteps[currentStepIndex].step
    }

    var currentBaseStepIndex: Int? {
        guard expandedSteps.indices.contains(currentStepIndex) else { return nil }
        return expandedSteps[currentStepIndex].baseIndex
    }

    var currentRepeatIndex: Int? {
        guard expandedSteps.indices.contains(currentStepIndex) else { return nil }
        return expandedSteps[currentStepIndex].repeatIndex
    }

    var currentRepeatTotal: Int? {
        guard expandedSteps.indices.contains(currentStepIndex) else { return nil }
        return expandedSteps[currentStepIndex].repeatTotal
    }

    func nextExerciseStep(from startIndex: Int) -> TrainingStep? {
        guard expandedSteps.indices.contains(startIndex) else { return nil }
        return expandedSteps[startIndex...].first(where: { $0.step.kind == .exercise })?.step
    }

    func upcomingExercises(from startIndex: Int, limit: Int) -> [TrainingStep] {
        guard expandedSteps.indices.contains(startIndex), limit > 0 else { return [] }
        let matches = expandedSteps[startIndex...].compactMap { entry -> TrainingStep? in
            entry.step.kind == .exercise ? entry.step : nil
        }
        return Array(matches.prefix(limit))
    }

    var currentStepNumber: Int {
        guard totalSteps > 0 else { return 0 }
        return min(currentStepIndex + 1, totalSteps)
    }

    private var elapsedSeconds: Int {
        if isCompleted { return totalTimeSeconds }

        let prepare = max(selectedPlan.prepareSeconds, 0)
        switch currentPhase {
        case .prepare:
            return max(prepare - remainingSeconds, 0)
        case .work, .rest:
            let completedSteps = expandedSteps.prefix(max(currentStepIndex, 0))
            let completedTotal = completedSteps.reduce(0) { total, entry in
                total + max(entry.step.durationSeconds, 0)
            }
            let currentElapsed = max(currentPhaseDuration - remainingSeconds, 0)
            return min(prepare + completedTotal + currentElapsed, totalTimeSeconds)
        case .complete:
            return totalTimeSeconds
        }
    }

    func formattedTime(_ seconds: Int) -> String {
        let clampedSeconds = max(seconds, 0)
        let minutes = clampedSeconds / 60
        let remainder = clampedSeconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    func toggleRunning() {
        isRunning ? pause() : start()
    }

    func start() {
        if isCompleted {
            reset()
        }
        guard !isRunning else { return }
        isRunning = true
        hasStarted = true
        if sessionStartedAt == nil {
            sessionStartedAt = Date()
        }
        startTimer()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func reset() {
        pause()
        isCompleted = false
        hasStarted = false
        currentStepIndex = 0
        sessionStartedAt = nil
        lastCompletedSession = nil
        rebuildExpandedSteps()

        if expandedSteps.isEmpty {
            currentPhase = .complete
            remainingSeconds = 0
            isCompleted = true
            return
        }

        if selectedPlan.prepareSeconds > 0 {
            currentPhase = .prepare
            remainingSeconds = selectedPlan.prepareSeconds
        } else {
            moveToStep(index: 0)
        }

        if remainingSeconds == 0 {
            advancePhase()
        }
    }

    func applyPlan(_ plan: TrainingPlan) {
        selectedPlan = plan.normalized()
        reset()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func tick() {
        guard isRunning else { return }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }

        if remainingSeconds <= 0 {
            advancePhase()
        }
    }

    private func advancePhase() {
        guard !isCompleted else { return }

        var safetyCounter = 0
        repeat {
            safetyCounter += 1

            switch currentPhase {
            case .prepare:
                moveToStep(index: 0)

            case .work, .rest:
                if currentStepIndex < totalSteps - 1 {
                    moveToStep(index: currentStepIndex + 1)
                } else {
                    completeWorkout()
                    return
                }

            case .complete:
                return
            }
        } while remainingSeconds == 0 && safetyCounter < 8
    }

    private func moveToStep(index: Int) {
        guard expandedSteps.indices.contains(index) else {
            completeWorkout()
            return
        }

        currentStepIndex = index
        let step = expandedSteps[index].step
        currentPhase = step.kind == .rest ? .rest : .work
        remainingSeconds = step.durationSeconds
        playPhaseSoundIfNeeded()
    }

    private func rebuildExpandedSteps() {
        expandedSteps = selectedPlan.steps.enumerated().flatMap { index, step in
            let repeats = max(step.repeatCount, 1)
            return (0..<repeats).map { rep in
                ExpandedStep(step: step, baseIndex: index, repeatIndex: rep + 1, repeatTotal: repeats)
            }
        }
    }

    private func completeWorkout() {
        guard !isCompleted else { return }
        if hasStarted {
            let startedAt = sessionStartedAt ?? Date()
            let completedAt = Date()
            let session = WorkoutSession(plan: selectedPlan, startedAt: startedAt, completedAt: completedAt)
            lastCompletedSession = session
            WorkoutSessionStore.shared.record(session)
            SoundPlayer.shared.play(.timerComplete)
        }
        pause()
        isCompleted = true
        currentPhase = .complete
        remainingSeconds = 0
    }

    private func playPhaseSoundIfNeeded() {
        guard isRunning else { return }
        switch currentPhase {
        case .work:
            SoundPlayer.shared.play(.timerWork)
        case .rest:
            SoundPlayer.shared.play(.timerRest)
        case .prepare, .complete:
            break
        }
    }
}

private struct ExpandedStep {
    let step: TrainingStep
    let baseIndex: Int
    let repeatIndex: Int
    let repeatTotal: Int
}

private enum AppSound: String {
    case timerWork = "timer_work"
    case timerRest = "timer_rest"
    case timerComplete = "timer_complete"

    var url: URL? {
        let extensions = ["wav", "mp3", "m4a", "caf"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: rawValue, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}

private final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [AppSound: AVAudioPlayer] = [:]
    private var isSessionConfigured = false

    func play(_ sound: AppSound) {
        guard let url = sound.url else { return }
        configureSessionIfNeeded()

        let player: AVAudioPlayer
        if let existing = players[sound] {
            player = existing
        } else if let created = try? AVAudioPlayer(contentsOf: url) {
            created.prepareToPlay()
            players[sound] = created
            player = created
        } else {
            return
        }

        player.currentTime = 0
        player.play()
    }

    private func configureSessionIfNeeded() {
        guard !isSessionConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
            isSessionConfigured = true
        } catch {
            isSessionConfigured = true
        }
    }
}
