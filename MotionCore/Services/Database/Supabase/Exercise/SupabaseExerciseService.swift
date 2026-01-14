// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseExerciseService.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 13.01.2026                                                       /
// Beschreibung  : Service für Exercise-Daten aus Supabase                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//

import Foundation

    /// Service für die Verwaltung von Exercises aus der Supabase-Datenbank
final class SupabaseExerciseService {
    static let shared = SupabaseExerciseService()
    private let client = SupabaseClient.shared

    private init() {}

    // MARK: - RPC Functions

    func fetchExercises(byMuscleGroup muscleGroup: String) async throws -> [SupabaseExercise] {
        let body: [String: Any] = [
            "p_muscle_identifier": muscleGroup  // *EDIT* - war falsch geschrieben
        ]

        return try await client.post(
            endpoint: "rpc/get_exercises_by_muscle",
            body: body
        )
    }

    func fetchExercises(byEquipment equipment: String) async throws -> [SupabaseExercise] {
        let body: [String: Any] = [
            "p_equipment_identifier": equipment  // *EDIT* - war falsch geschrieben
        ]

        return try await client.post(
            endpoint: "rpc/get_exercises_by_equipment",
            body: body
        )
    }

    func searchExercises(byName searchText: String) async throws -> [SupabaseExercise] {
        let body: [String: Any] = [
            "search_term": searchText  // *EDIT* - Parameter-Name korrigiert
        ]

        return try await client.post(
            endpoint: "rpc/search_exercises_by_name",
            body: body
        )
    }

        // MARK: - Alternative ohne Limit-Parameter
    func fetchAllExercises(languageCode: String = "de") async throws -> [SupabaseExercise] {
        let body: [String: Any] = [
            "p_language_code": languageCode,
            "p_limit": 2000  // Hoher Default-Wert für "alle"
        ]

        return try await client.post(
            endpoint: "rpc/get_exercises_with_details",
            body: body
        )
    }
}
