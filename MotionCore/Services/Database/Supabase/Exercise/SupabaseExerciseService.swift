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

    // MARK: - RPC Functions (Legacy)

    func fetchExercises(byMuscleGroup muscleGroup: String, languageCode: String = "de") async throws -> [SupabaseExercise] {
        let body: [String: Any] = [
            "p_muscle_identifier": muscleGroup,
            "p_language_code": languageCode
        ]

        return try await client.post(
            endpoint: "rpc/get_exercises_by_muscle",
            body: body
        )
    }

    func fetchExercises(byEquipment equipment: String, languageCode: String = "de") async throws -> [SupabaseExercise] {
        let body: [String: Any] = [
            "p_equipment_identifier": equipment,
            "p_language_code": languageCode
        ]

        return try await client.post(
            endpoint: "rpc/get_exercises_by_equipment",
            body: body
        )
    }

    func searchExercisesByName(_ searchText: String, languageCode: String = "de") async throws -> [SupabaseExercise] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= 2 else { return [] }

        let body: [String: Any] = [
            "p_search_term": term,
            "p_language_code": languageCode
        ]

        return try await client.post(
            endpoint: "rpc/search_exercises_by_name",
            body: body
        )
    }

    // MARK: - Advanced Search (NEW)

    /// Generische Suche mit optionalen Filtern
    /// - Parameters:
    ///   - searchTerm: Optional - Suchtext für Namen (>= 2 Zeichen)
    ///   - equipmentId: Optional - Equipment UUID Filter
    ///   - muscleGroupId: Optional - MuscleGroup UUID Filter (Level 1 oder Level 2)
    ///   - languageCode: Sprache für Übersetzungen (default: "de")
    ///   - limit: Max. Anzahl Ergebnisse (default: 20)
    ///   - offset: Offset für Paging (default: 0)
    /// - Returns: Array von SupabaseExerciseSearchResult
    func searchExercises(
        byName searchTerm: String? = nil,
        equipmentId: UUID? = nil,
        muscleGroupId: UUID? = nil,
        languageCode: String = "de",
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [SupabaseExerciseSearchResult] {

        var params: [String: Any] = [
            "p_language_code": languageCode,
            "p_limit": limit,
            "p_offset": offset
        ]

        // Optional: Suchtext (min. 2 Zeichen)
        if let searchTerm {
            let trimmed = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= 2 {
                params["p_search_term"] = trimmed
            }
        }

        // Optional: Equipment UUID (als String für PostgreSQL)
        if let equipmentId {
            params["p_equipment_id"] = equipmentId.uuidString
        }

        // Optional: MuscleGroup UUID (als String für PostgreSQL)
        if let muscleGroupId {
            params["p_muscle_group_id"] = muscleGroupId.uuidString
        }

        print("🔍 Search Exercises with params: \(params)")

        let results: [SupabaseExerciseSearchResult] = try await client.rpc(
            function: "search_exercises",
            params: params
        )

        print("✅ Found \(results.count) exercises")

        return results
    }

    // MARK: - Fetch All

    func fetchAllExercises(languageCode: String = "de") async throws -> [SupabaseExercise] {
        let body: [String: Any] = [
            "p_language_code": languageCode,
            "p_limit": 2000
        ]

        return try await client.post(
            endpoint: "rpc/get_exercises_with_details",
            body: body
        )
    }
}
