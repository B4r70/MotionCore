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

// Service für die Verwaltung von Exercises aus der Supabase-Datenbank
final class SupabaseExerciseService {
    static let shared = SupabaseExerciseService()
    private let client = SupabaseClient.shared

    private init() {}

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
