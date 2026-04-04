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
import Foundation

struct SupabaseExercise: Codable, Identifiable {
    let id: UUID

    let exerciseDbId: String?
    let category: String?
    let forceType: String?
    let mechanicType: String?
    let difficulty: String?

    let videoPath: String?
    let posterPath: String?
    let thumbnailUrl: String?
    let source: String?

    let isVerified: Bool
    let isArchived: Bool

    let createdAt: Date
    let updatedAt: Date

    let name: String
    let instructions: String?
    let tips: String?

    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseDbId   = "exercise_db_id"
        case category
        case forceType      = "force_type"
        case mechanicType   = "mechanic_type"
        case difficulty
        case videoPath      = "video_path"
        case posterPath     = "poster_path"
        case thumbnailUrl   = "thumbnail_url"
        case source
        case isVerified     = "is_verified"
        case isArchived     = "is_archived"
        case createdAt      = "created_at"
        case updatedAt      = "updated_at"
        case name
        case instructions
        case tips
        case primaryMuscles   = "primary_muscles"
        case secondaryMuscles = "secondary_muscles"
        case equipment
    }
}
