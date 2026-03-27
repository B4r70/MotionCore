//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : ExerciseImportManager.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 08.01.2026                                                       /
// Beschreibung  : Import-Manager für Übungen aus Supabase                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

/// Manager für den Import von Übungen aus der Supabase-Datenbank
class ExerciseImportManager {

    // MARK: - Single Exercise Import

    /// Importiert eine einzelne Exercise aus Supabase in SwiftData
    /// - Parameters:
    ///   - supabaseExercise: Die Supabase-Exercise (enthält bereits deutsche Übersetzung)
    ///   - context: SwiftData ModelContext
    static func importFromSupabase(
        _ supabaseExercise: SupabaseExercise,
        context: ModelContext
    ) throws {
        // Prüfen ob Exercise bereits existiert (anhand apiID)
        let exerciseID = supabaseExercise.id
        let fetchDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.apiID == exerciseID }
        )

        if try context.fetch(fetchDescriptor).first != nil {
            print("⭐️ Exercise '\(supabaseExercise.name)' bereits vorhanden (ID: \(supabaseExercise.id))")
            return
        }

        // Neues Exercise erstellen
        let newExercise = Exercise(from: supabaseExercise)
        context.insert(newExercise)

        try context.save()
        print("✅ Exercise importiert: \(newExercise.name)")
    }

    // MARK: - Batch Import

    /// Importiert mehrere Exercises aus Supabase in einem Batch
    /// - Parameters:
    ///   - exercises: Array von Supabase-Exercises (mit deutschen Übersetzungen)
    ///   - context: SwiftData ModelContext
    ///   - progressHandler: Optional - Callback für Progress-Updates (current, total)
    static func batchImportFromSupabase(
        _ exercises: [SupabaseExercise],
        context: ModelContext,
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async throws {
        print("🚀 Starte Batch-Import von \(exercises.count) Exercises...")

        var imported = 0
        var skipped = 0

        for (index, supabaseExercise) in exercises.enumerated() {
            // Prüfen ob bereits vorhanden
            let exerciseID = supabaseExercise.id
            let fetchDescriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate { $0.apiID == exerciseID }
            )

            if (try? context.fetch(fetchDescriptor).first) != nil {
                skipped += 1
                print("⭐️ [\(index+1)/\(exercises.count)] Überspringe: \(supabaseExercise.name)")
            } else {
                // Importieren
                let newExercise = Exercise(from: supabaseExercise)
                context.insert(newExercise)
                imported += 1
                print("✅ [\(index+1)/\(exercises.count)] Importiert: \(newExercise.name)")
            }

            // Progress-Update
            progressHandler?(index + 1, exercises.count)

            // Speichern alle 50 Exercises
            if (index + 1) % 50 == 0 {
                try context.save()
                print("💾 Zwischenspeicherung bei \(index + 1) Exercises")

                // Kurze Pause um UI responsive zu halten
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
        }

        // Finale Speicherung
        try context.save()

        print("✅ Batch-Import abgeschlossen:")
        print("   - Gesamt: \(exercises.count)")
        print("   - Importiert: \(imported)")
        print("   - Übersprungen: \(skipped)")
    }

    // MARK: - Full Database Import

    /// Importiert die komplette Exercise-Datenbank aus Supabase
    /// - Parameters:
    ///   - context: SwiftData ModelContext
    ///   - progressHandler: Optional - Callback für Progress-Updates
    static func importFullDatabase(
        context: ModelContext,
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async throws {
        print("🚀 Starte vollständigen Datenbank-Import von Supabase...")

        // Alle Exercises von Supabase laden (mit deutschen Übersetzungen aus JOIN!)
        let exercises = try await SupabaseExerciseService.shared.fetchAllExercises()
        print("📥 \(exercises.count) Exercises von Supabase geladen (mit deutschen Übersetzungen)")

        // Batch-Import durchführen
        try await batchImportFromSupabase(
            exercises,
            context: context,
            progressHandler: progressHandler
        )
    }

    // MARK: - Delete Exercise

    /// Löscht eine importierte Exercise aus der Datenbank
    /// - Parameters:
    ///   - exercise: Das zu löschende Exercise
    ///   - context: SwiftData ModelContext
    static func deleteExercise(
        _ exercise: Exercise,
        context: ModelContext
    ) throws {
        // Nur System-Exercises können gelöscht werden
        guard exercise.isSystemExercise else {
            print("⚠️ Nur importierte Exercises können gelöscht werden")
            return
        }

        let name = exercise.name
        context.delete(exercise)
        try context.save()
        print("🗑️ Gelöscht: \(name)")
    }

    // MARK: - Helper Methods

    /// Prüft ob eine Exercise bereits in der Datenbank existiert
    /// - Parameters:
    ///   - apiID: Die Supabase Exercise-ID
    ///   - context: SwiftData ModelContext
    /// - Returns: true wenn Exercise existiert, sonst false
    static func exerciseExists(
        apiID: UUID?,
        context: ModelContext
    ) -> Bool {
        guard let apiID else { return false }
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.apiID == apiID }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    /// Gibt Statistiken über importierte Exercises zurück
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Tuple mit (total, supabase, custom)
    static func getImportStatistics(context: ModelContext) throws -> (total: Int, supabase: Int, custom: Int) {
        let allDescriptor = FetchDescriptor<Exercise>()
        let total = try context.fetchCount(allDescriptor)

        let supabaseDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.apiProvider == "supabase" }
        )
        let supabase = try context.fetchCount(supabaseDescriptor)

        let customDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.isCustom == true }
        )
        let custom = try context.fetchCount(customDescriptor)

        return (total, supabase, custom)
    }

    // MARK: - In-Place Enrichment

    /// Reichert bestehende Exercises um feingranulare DetailedMuscle-Daten an.
    /// Lädt Exercises von Supabase und aktualisiert NUR die neuen Felder.
    /// Alle Relationships, Favoriten, RepRanges, Trainingspläne etc. bleiben komplett unberührt.
    ///
    /// SICHERHEITS-GARANTIE: Diese Methode löscht KEINE Exercises und ändert KEINE
    /// bestehenden Felder. Sie befüllt ausschließlich detailedPrimaryMusclesRaw und
    /// detailedSecondaryMusclesRaw auf bestehenden Objekten.
    static func enrichWithDetailedMuscles(
        context: ModelContext,
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async throws {
        print("🔬 Starte DetailedMuscle Enrichment...")

        // 1. Alle Supabase-Exercises laden (mit Muscle-Identifiers)
        let supabaseExercises = try await SupabaseExerciseService.shared.fetchAllExercises()
        print("📥 \(supabaseExercises.count) Exercises von Supabase geladen")

        // 2. Lokale Exercises mit apiID laden
        let descriptor = FetchDescriptor<Exercise>()
        let allLocal = try context.fetch(descriptor)
        let localWithApiID = allLocal.filter { $0.apiID != nil }
        print("📦 \(localWithApiID.count) lokale Exercises mit apiID gefunden")

        // 3. Lookup: apiID → lokale Exercise
        let localByApiID = Dictionary(
            uniqueKeysWithValues: localWithApiID.compactMap { ex -> (UUID, Exercise)? in
                guard let apiID = ex.apiID else { return nil }
                return (apiID, ex)
            }
        )

        // 4. Anreicherung — NUR die neuen Felder setzen
        var enriched = 0
        var skipped = 0
        for (index, supabaseExercise) in supabaseExercises.enumerated() {
            guard let local = localByApiID[supabaseExercise.id] else {
                skipped += 1
                continue
            }

            // Nur befüllen wenn noch leer (idempotent)
            guard local.detailedPrimaryMusclesRaw.isEmpty else {
                skipped += 1
                continue
            }

            // Setter verwenden — synchronisiert auch primaryMusclesRaw automatisch
            local.detailedPrimaryMuscles = supabaseExercise.primaryMuscles
                .compactMap { DetailedMuscle(rawValue: $0.lowercased()) }
            local.detailedSecondaryMuscles = supabaseExercise.secondaryMuscles
                .compactMap { DetailedMuscle(rawValue: $0.lowercased()) }

            enriched += 1
            progressHandler?(index + 1, supabaseExercises.count)

            // Zwischenspeichern alle 100 Exercises
            if enriched % 100 == 0 {
                try context.save()
            }
        }

        // Finale Speicherung
        try context.save()

        print("✅ Enrichment abgeschlossen:")
        print("   - Angereichert: \(enriched)")
        print("   - Übersprungen: \(skipped)")
    }
}
