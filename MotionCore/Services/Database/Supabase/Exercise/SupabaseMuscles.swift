//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services/Supabase                                                /
// Datei . . . . : SupabaseMuscles.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.01.2026                                                       /
// Beschreibung  : Models für Supabase Filter (Equipment, MuscleGroups)             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - MuscleGroup

struct SupabaseMuscles: Codable, Identifiable, Hashable {
    let id: UUID
    let identifier: String
    let parentId: UUID?
    let hierarchyLevel: Int
    let displayOrder: Int?
    let name: String
    let description: String?

    var isPrimaryGroup: Bool {
        hierarchyLevel == 1 && parentId == nil
    }

    var isSubgroup: Bool {
        hierarchyLevel == 2 && parentId != nil
    }
}
