//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : API                                                              /
// Datei . . . . : ExerciseDBResponse.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.01.2026                                                       /
// Beschreibung  : Response-Modell für die ExerciseDB API-Integration               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Dieses Modell repräsentiert die JSON-Struktur der ExerciseDB     /
//                API (exercise-db-fitness-workout-gym.p.rapidapi.com).             /
//                Alle Properties sind entsprechend der API-Response definiert,     /
//                viele davon als Optional, da die API nicht alle Felder für jede  /
//                Übung zurückgibt.                                                 /
// ---------------------------------------------------------------------------------/
//
import Foundation

    // MARK: - RapidAPI Exercise Response
    /// Haupt-Response-Modell für Übungen von ExerciseDB RapidAPI
struct RapidAPIExercise: Codable, Identifiable {
    let id: String
    let name: String
    let bodyPart: String
    let target: String
    let equipment: String
    let secondaryMuscles: [String]?
    let instructions: [String]?
    let description: String?
    let difficulty: String?
    let category: String?
}

    // MARK: - Unified Exercise
    /// Einheitliches Format für den Import Manager
struct UnifiedExercise {
    let id: String
    let name: String
    let bodyParts: [String]
    let targetMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: [String]
    let instructions: [String]
    let description: String?
    let difficulty: String?
    let category: String?

    // Externe Medien (URLs!)
    let externalVideoURL: String?
    let externalImageURL: String?
}

    // MARK: - Conversion Extension
extension RapidAPIExercise {
    func toUnified() -> UnifiedExercise {
        UnifiedExercise(
            id: id,
            name: name,
            bodyParts: [bodyPart],
            targetMuscles: [target],
            secondaryMuscles: secondaryMuscles ?? [],
            equipment: [equipment],
            instructions: instructions ?? [],
            description: description,
            difficulty: difficulty,
            category: category,
            externalVideoURL: nil,
            externalImageURL: nil
        )
    }
}

    // MARK: - Legacy Support
    /// Response-Modell für die Exercise-IDs-Liste (falls noch benötigt)
struct ExerciseIdListResponse: Decodable {
    let excercise_ids: [String]
}
