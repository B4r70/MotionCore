// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Models                                                           /
// Datei . . . . : ActiveSessionState.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.01.2026                                                       /
// Beschreibung  : Datenmodell für die Abbildung aktiver Sessions                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
// MARK: - Active Session State

// Zustand einer pausierten Session (für UserDefaults-Persistenz)
import Foundation

struct ActiveSessionState: Codable {
    let sessionUUID: String
    let workoutType: String
    let startedAt: Date
    let pausedAt: Date
    let accumulatedSeconds: Int
    let isPaused: Bool

    // NEU
    let selectedExerciseKey: String?

    func totalElapsedSeconds(at date: Date = Date()) -> Int {
        if isPaused {
            return accumulatedSeconds
        } else {
            let additionalSeconds = Int(date.timeIntervalSince(pausedAt))
            return accumulatedSeconds + max(0, additionalSeconds)
        }
    }

    enum CodingKeys: String, CodingKey {
        case sessionUUID
        case workoutType
        case startedAt
        case pausedAt
        case accumulatedSeconds
        case isPaused
        case selectedExerciseKey
        case selectedExerciseIndex // legacy (nur beim Decoding)
    }

    init(
        sessionUUID: String,
        workoutType: String,
        startedAt: Date,
        pausedAt: Date,
        accumulatedSeconds: Int,
        isPaused: Bool,
        selectedExerciseKey: String?
    ) {
        self.sessionUUID = sessionUUID
        self.workoutType = workoutType
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.accumulatedSeconds = accumulatedSeconds
        self.isPaused = isPaused
        self.selectedExerciseKey = selectedExerciseKey
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        sessionUUID = try c.decode(String.self, forKey: .sessionUUID)
        workoutType = try c.decode(String.self, forKey: .workoutType)
        startedAt = try c.decode(Date.self, forKey: .startedAt)
        pausedAt = try c.decode(Date.self, forKey: .pausedAt)
        accumulatedSeconds = try c.decode(Int.self, forKey: .accumulatedSeconds)
        isPaused = try c.decode(Bool.self, forKey: .isPaused)

        if let key = try c.decodeIfPresent(String.self, forKey: .selectedExerciseKey) {
            selectedExerciseKey = key
        } else {
            // legacy Feld nur "schlucken"
            _ = try c.decodeIfPresent(Int.self, forKey: .selectedExerciseIndex)
            selectedExerciseKey = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        try c.encode(sessionUUID, forKey: .sessionUUID)
        try c.encode(workoutType, forKey: .workoutType)
        try c.encode(startedAt, forKey: .startedAt)
        try c.encode(pausedAt, forKey: .pausedAt)
        try c.encode(accumulatedSeconds, forKey: .accumulatedSeconds)
        try c.encode(isPaused, forKey: .isPaused)

        try c.encodeIfPresent(selectedExerciseKey, forKey: .selectedExerciseKey)
        // selectedExerciseIndex wird absichtlich NICHT mehr encoded
    }
}
