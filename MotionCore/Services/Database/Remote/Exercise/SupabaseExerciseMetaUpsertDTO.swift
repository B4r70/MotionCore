// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseExerciseMetaUpsertDTO.swift                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.04.2026                                                       /
// Beschreibung  : Encodable-Schwester zu `SupabaseExercise`. Push der lokalen      /
//                 Übungs-Stammdaten nach Supabase (Backup). iCloud ist Source of   /
//                 Truth — alle lokal verfügbaren Felder dürfen geschrieben werden, /
//                 NOT-NULL-Spalten (category, difficulty) sind Pflicht.            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - SupabaseExerciseMetaUpsertDTO

/// Encodable-Schwester zu `SupabaseExercise`.
/// Push der lokalen Übungs-Stammdaten nach Supabase (Backup). iCloud ist Source of Truth.
/// `category` und `difficulty` sind in `motioncore.exercises` NOT NULL und daher Pflicht.
/// Vollständige CodingKeys wegen CodingKeys-Trap: bei vorhandenem CodingKeys-Enum ignoriert
/// der JSONEncoder das keyEncodingStrategy komplett — alle Felder müssen explizit gelistet sein.
struct SupabaseExerciseMetaUpsertDTO: Encodable {
    let id:                       UUID
    let category:                 String
    let difficulty:               String
    let mechanicType:             String?
    let forceType:                String?
    let posterPath:               String?
    let videoPath:                String?
    let movementPattern:          String?
    let bodyPosition:             String?
    let isUnilateral:             Bool?
    let repRangeMin:              Int?
    let repRangeMax:              Int?
    let targetRIR:                Int?
    let progressionMode:          String?
    let customTargetReps:         Int?
    let progressionStep:          Double?
    let detailedPrimaryMuscles:   [String]?
    let detailedSecondaryMuscles: [String]?
    let metaUpdatedAt:            Date

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case difficulty
        case mechanicType             = "mechanic_type"
        case forceType                = "force_type"
        case posterPath               = "poster_path"
        case videoPath                = "video_path"
        case movementPattern          = "movement_pattern"
        case bodyPosition             = "body_position"
        case isUnilateral             = "is_unilateral"
        case repRangeMin              = "rep_range_min"
        case repRangeMax              = "rep_range_max"
        case targetRIR                = "target_rir"
        case progressionMode          = "progression_mode"
        case customTargetReps         = "custom_target_reps"
        case progressionStep          = "progression_step"
        case detailedPrimaryMuscles   = "detailed_primary_muscles"
        case detailedSecondaryMuscles = "detailed_secondary_muscles"
        case metaUpdatedAt            = "meta_updated_at"
    }
}
