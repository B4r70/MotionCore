//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services/Supabase                                                /
// Datei . . . . : SupabaseFilterModels.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 20.01.2026                                                       /
// Beschreibung  : Models für Supabase Filter (Equipment, MuscleGroups)             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Equipment

struct SupabaseEquipment: Codable, Identifiable, Hashable {
    let id: UUID
    let identifier: String
    let category: String?
    let displayOrder: Int?
    let name: String
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case identifier
        case category
        case displayOrder = "display_order"
        case name
        case description
    }
}
