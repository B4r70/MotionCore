// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseExerciseModels.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 13.01.2026                                                       /
// Beschreibung  : Datenmodelle für Supabase Exercise-Daten                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//

/* *NEW* Gesamte Datei */

import Foundation

/// Repräsentiert eine Exercise aus der Supabase-Datenbank (mit JOINs)
struct SupabaseExercise: Codable, Identifiable {
    let id: String
    let exerciseDbId: String
    let category: String
    let difficulty: String
    let forceType: String?
    let mechanicType: String?
    let gifFilename: String?
    let videoUrl: String?
    let name: String
    let instructions: String?
    let tips: String?
    let primaryMuscles: [String]?
    let secondaryMuscles: [String]?
    let equipment: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseDbId = "exercise_db_id"
        case category
        case difficulty
        case forceType = "force_type"
        case mechanicType = "mechanic_type"
        case gifFilename = "gif_filename"
        case videoUrl = "video_url"
        case name
        case instructions
        case tips
        case primaryMuscles = "primary_muscles"
        case secondaryMuscles = "secondary_muscles"
        case equipment
    }
}

/// Repräsentiert eine Übersetzung (optional - falls wir separate Abfrage machen)
struct SupabaseExerciseTranslation: Codable, Identifiable {
    let id: String
    let exerciseId: String
    let languageCode: String
    let name: String
    let instructions: String?
    let tips: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case languageCode = "language_code"
        case name
        case instructions
        case tips
    }
}
