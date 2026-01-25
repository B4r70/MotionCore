//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services/Supabase                                                /
// Datei . . . . : SupabaseFilterService.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 20.01.2026                                                       /
// Beschreibung  : Service zum Laden von Equipment & MuscleGroups für Filter        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import Combine

final class SupabaseFilterService: ObservableObject {
    static let shared = SupabaseFilterService()

    private let client = SupabaseClient.shared

    // Cache für geladene Daten
    @Published private(set) var equipments: [SupabaseEquipment] = []
    @Published private(set) var muscleGroups: [SupabaseMuscles] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    // Computed: Hierarchisch gruppierte MuscleGroups
    var muscleGroupHierarchy: [SupabaseMusclesHierarchy] {
        muscleGroups.grouped()
    }

    // Computed: Nur Level 1 (Hauptgruppen)
    var primaryMuscleGroups: [SupabaseMuscles] {
        muscleGroups.filter { $0.isPrimaryGroup }
            .sorted { ($0.displayOrder ?? 999) < ($1.displayOrder ?? 999) }
    }

    private init() {}

    // MARK: - Load Equipment

    @MainActor
    func loadEquipment(languageCode: String = "de") async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let result: [SupabaseEquipment] = try await client.rpc(
                function: "list_equipment",
                params: ["p_language_code": languageCode]
            )

            self.equipments = result.sorted { ($0.displayOrder ?? 999) < ($1.displayOrder ?? 999) }

            print("✅ Loaded \(result.count) equipments")
        } catch {
            self.error = "Equipment konnte nicht geladen werden: \(error.localizedDescription)"
            print("❌ Equipment load error: \(error)")
            throw error
        }
    }

    // MARK: - Load Muscle Groups

    // Lädt ALLE Muscle Groups (Level 1 + Level 2)
    @MainActor
    func loadMuscleGroups(languageCode: String = "de") async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            // Level 1 laden
            let level1: [SupabaseMuscles] = try await client.rpc(
                function: "list_muscle_groups",
                params: ["p_language_code": languageCode]
            )

            // Level 2 laden (alle Subgroups)
            let level2: [SupabaseMuscles] = try await client.rpc(
                function: "list_muscle_subgroups_all",
                params: ["p_language_code": languageCode]
            )

            // Kombinieren
            self.muscleGroups = level1 + level2

            print("✅ Loaded \(level1.count) primary muscle groups + \(level2.count) subgroups")
        } catch {
            self.error = "MuscleGroups konnten nicht geladen werden: \(error.localizedDescription)"
            print("❌ MuscleGroups load error: \(error)")
            throw error
        }
    }

    // MARK: - Load All Filters

    // Lädt Equipment UND MuscleGroups gleichzeitig
    @MainActor
    func loadAllFilters(languageCode: String = "de") async {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        async let equipmentTask: () = loadEquipment(languageCode: languageCode)
        async let muscleGroupTask: () = loadMuscleGroups(languageCode: languageCode)
        
        do {
            _ = try await (equipmentTask, muscleGroupTask)  // ✅ FIX
            print("✅ All filters loaded successfully")
        } catch {
            self.error = "Filter konnten nicht geladen werden"
            print("❌ Filter load error: \(error)")
        }
    }

    // MARK: - Subgroups für Primary Group

    // Gibt alle Subgroups für eine Primary Group zurück
    func subgroups(for primaryGroup: SupabaseMuscles) -> [SupabaseMuscles] {
        guard primaryGroup.isPrimaryGroup else { return [] }

        return muscleGroups
            .filter { $0.parentId == primaryGroup.id }
            .sorted { ($0.displayOrder ?? 999) < ($1.displayOrder ?? 999) }
    }

    // Gibt alle Subgroups für einen Primary Group Identifier zurück
    func subgroups(forIdentifier identifier: String) -> [SupabaseMuscles] {
        guard let primary = primaryMuscleGroups.first(where: { $0.identifier == identifier }) else {
            return []
        }
        return subgroups(for: primary)
    }
}
