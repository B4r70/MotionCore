//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services/Supabase                                                /
// Datei . . . . : SupabaseMuscleGroups.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.01.2026                                                       /
// Beschreibung  : Models für Supabase Filter (Equipment, MuscleGroups)             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Gruppierte Muscle Groups (für UI)

struct SupabaseMusclesHierarchy: Identifiable {
    let id: UUID
    let primary: SupabaseMuscles  // Level 1
    let subgroups: [SupabaseMuscles]  // Level 2
    
    var name: String { primary.name }
    var identifier: String { primary.identifier }
}

// MARK: - Helper Extension

extension Array where Element == SupabaseMuscles {
    /// Gruppiert alle MuscleGroups hierarchisch (Level 1 mit ihren Level 2 Children)
    func grouped() -> [SupabaseMusclesHierarchy] {
        let primaryGroups = self.filter { $0.isPrimaryGroup }
        let subgroups = self.filter { $0.isSubgroup }
        
        return primaryGroups.map { primary in
            let children = subgroups.filter { $0.parentId == primary.id }
                .sorted { ($0.displayOrder ?? 999) < ($1.displayOrder ?? 999) }
            
            return SupabaseMusclesHierarchy(
                id: primary.id,
                primary: primary,
                subgroups: children
            )
        }
        .sorted { ($0.primary.displayOrder ?? 999) < ($1.primary.displayOrder ?? 999) }
    }
}
