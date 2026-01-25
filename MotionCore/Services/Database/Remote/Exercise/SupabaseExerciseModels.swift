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

struct SupabaseExercise: Decodable, Identifiable {
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
}
