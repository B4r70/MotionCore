// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseExerciseSearchResult.swift                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 20.01.2026                                                       /
// Beschreibung  : Datenmodelle für Supabase Exercise-Daten                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

    /// Lightweight DTO returned by `public.search_exercises` RPC.
    /// EXTENDED Version mit videoPath, posterPath, category, forceType, mechanicType
struct SupabaseExerciseSearchResult: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let equipment: [String]
    let muscles: [String]
    let difficulty: String?
    
        // NEU: Felder aus exercises Tabelle
    let videoPath: String?
    let posterPath: String?
    let category: String?
    let forceType: String?
    let mechanicType: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case equipment
        case muscles
        case difficulty
        case videoPath = "video_path"
        case posterPath = "poster_path"
        case category
        case forceType = "force_type"
        case mechanicType = "mechanic_type"
    }
}
