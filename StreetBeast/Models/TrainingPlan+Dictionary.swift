import Foundation

extension TrainingStep {
    func toDictionary() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "kind": kind.rawValue,
            "exerciseName": exerciseName,
            "durationSeconds": durationSeconds,
            "repeatCount": repeatCount
        ]
        if let exerciseId {
            data["exerciseId"] = exerciseId
        }
        return data
    }

    static func fromDictionary(_ data: [String: Any]) -> TrainingStep? {
        let idString = data["id"] as? String ?? UUID().uuidString
        let id = UUID(uuidString: idString) ?? UUID()
        let kindRaw = data["kind"] as? String ?? TrainingStepKind.exercise.rawValue
        let kind = TrainingStepKind(rawValue: kindRaw) ?? .exercise
        let exerciseName = data["exerciseName"] as? String ?? ""
        let durationSeconds = intValue(from: data["durationSeconds"]) ?? 0
        let repeatCount = intValue(from: data["repeatCount"]) ?? 1
        let exerciseId = data["exerciseId"] as? String

        var step = TrainingStep(
            id: id,
            kind: kind,
            exercise: nil,
            exerciseName: exerciseName,
            durationSeconds: durationSeconds,
            repeatCount: repeatCount
        )
        step.exerciseId = exerciseId
        return step
    }
}

extension TrainingPlan {
    func toDictionary() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "prepareSeconds": prepareSeconds,
            "steps": steps.map { $0.toDictionary() }
        ]
        if let nameKey {
            data["nameKey"] = nameKey
        }
        return data
    }

    static func fromDictionary(_ data: [String: Any]) -> TrainingPlan? {
        guard let name = data["name"] as? String else { return nil }
        let idString = data["id"] as? String ?? UUID().uuidString
        let id = UUID(uuidString: idString) ?? UUID()
        let prepareSeconds = intValue(from: data["prepareSeconds"]) ?? 0
        let nameKey = data["nameKey"] as? String

        let rawSteps = data["steps"] as? [[String: Any]]
            ?? (data["steps"] as? [Any])?.compactMap { $0 as? [String: Any] }
            ?? []
        let steps = rawSteps.compactMap { TrainingStep.fromDictionary($0) }

        return TrainingPlan(
            id: id,
            name: name,
            nameKey: nameKey,
            prepareSeconds: prepareSeconds,
            steps: steps
        )
    }
}

private func intValue(from value: Any?) -> Int? {
    if let intValue = value as? Int { return intValue }
    if let int64Value = value as? Int64 { return Int(int64Value) }
    if let doubleValue = value as? Double { return Int(doubleValue) }
    if let number = value as? NSNumber { return number.intValue }
    return nil
}
