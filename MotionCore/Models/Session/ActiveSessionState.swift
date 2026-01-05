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
    let sessionID: String
    let workoutType: String
    let startedAt: Date
    let pausedAt: Date
    let accumulatedSeconds: Int
    let isPaused: Bool
    let selectedExerciseKey: String?

    func totalElapsedSeconds(at date: Date = Date()) -> Int {
        if isPaused { return accumulatedSeconds }
        let additionalSeconds = Int(date.timeIntervalSince(pausedAt))
        return accumulatedSeconds + max(0, additionalSeconds)
    }

    enum CodingKeys: String, CodingKey {
        case sessionID
        case sessionUUID // legacy
        case workoutType
        case startedAt
        case pausedAt
        case accumulatedSeconds
        case isPaused
        case selectedExerciseKey
        case selectedExerciseIndex // legacy
    }

    init(
        sessionID: String,
        workoutType: String,
        startedAt: Date,
        pausedAt: Date,
        accumulatedSeconds: Int,
        isPaused: Bool,
        selectedExerciseKey: String?
    ) {
        self.sessionID = sessionID
        self.workoutType = workoutType
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.accumulatedSeconds = accumulatedSeconds
        self.isPaused = isPaused
        self.selectedExerciseKey = selectedExerciseKey
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // ✅ new key first, fallback to legacy key
        if let id = try c.decodeIfPresent(String.self, forKey: .sessionID) {
            sessionID = id
        } else if let legacy = try c.decodeIfPresent(String.self, forKey: .sessionUUID) {
            sessionID = legacy
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.sessionID,
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Neither sessionID nor sessionUUID found.")
            )
        }

        workoutType = try c.decode(String.self, forKey: .workoutType)
        startedAt = try c.decode(Date.self, forKey: .startedAt)
        pausedAt = try c.decode(Date.self, forKey: .pausedAt)
        accumulatedSeconds = try c.decode(Int.self, forKey: .accumulatedSeconds)
        isPaused = try c.decode(Bool.self, forKey: .isPaused)

        if let key = try c.decodeIfPresent(String.self, forKey: .selectedExerciseKey) {
            selectedExerciseKey = key
        } else {
            _ = try c.decodeIfPresent(Int.self, forKey: .selectedExerciseIndex) // legacy swallow
            selectedExerciseKey = nil
        }
        // Session ID darf nicht leer sein
        if sessionID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "sessionID is empty."
            ))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        // ✅ Nur noch der neue Key wird geschrieben
        try c.encode(sessionID, forKey: .sessionID)
        try c.encode(workoutType, forKey: .workoutType)
        try c.encode(startedAt, forKey: .startedAt)
        try c.encode(pausedAt, forKey: .pausedAt)
        try c.encode(accumulatedSeconds, forKey: .accumulatedSeconds)
        try c.encode(isPaused, forKey: .isPaused)
        try c.encodeIfPresent(selectedExerciseKey, forKey: .selectedExerciseKey)
    }
}
