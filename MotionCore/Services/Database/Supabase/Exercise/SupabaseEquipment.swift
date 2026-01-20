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

// MARK: - MuscleGroup

struct SupabaseMuscleGroup: Codable, Identifiable, Hashable {
    let id: UUID
    let identifier: String
    let parentId: UUID?
    let hierarchyLevel: Int
    let displayOrder: Int?
    let name: String
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case identifier
        case parentId = "parent_id"
        case hierarchyLevel = "hierarchy_level"
        case displayOrder = "display_order"
        case name
        case description
    }
    
    // Helper: Ist Level 1 (Hauptgruppe)?
    var isPrimaryGroup: Bool {
        hierarchyLevel == 1 && parentId == nil
    }
    
    // Helper: Ist Level 2 (Untergruppe)?
    var isSubgroup: Bool {
        hierarchyLevel == 2 && parentId != nil
    }
}

// MARK: - Gruppierte Muscle Groups (für UI)

struct MuscleGroupHierarchy: Identifiable {
    let id: UUID
    let primary: SupabaseMuscleGroup  // Level 1
    let subgroups: [SupabaseMuscleGroup]  // Level 2
    
    var name: String { primary.name }
    var identifier: String { primary.identifier }
}

// MARK: - Helper Extension

extension Array where Element == SupabaseMuscleGroup {
    /// Gruppiert alle MuscleGroups hierarchisch (Level 1 mit ihren Level 2 Children)
    func grouped() -> [MuscleGroupHierarchy] {
        let primaryGroups = self.filter { $0.isPrimaryGroup }
        let subgroups = self.filter { $0.isSubgroup }
        
        return primaryGroups.map { primary in
            let children = subgroups.filter { $0.parentId == primary.id }
                .sorted { ($0.displayOrder ?? 999) < ($1.displayOrder ?? 999) }
            
            return MuscleGroupHierarchy(
                id: primary.id,
                primary: primary,
                subgroups: children
            )
        }
        .sorted { ($0.primary.displayOrder ?? 999) < ($1.primary.displayOrder ?? 999) }
    }
}
