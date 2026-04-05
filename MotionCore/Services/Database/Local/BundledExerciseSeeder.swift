//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services/Database/Local                                          /
// Datei . . . . : BundledExerciseSeeder.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 04.04.2026                                                       /
// Beschreibung  : Versions-basierter Seeder für gebündelte Exercise-JSON-Daten     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// MARK: - BundledExerciseSeeder

struct BundledExerciseSeeder {

    // UserDefaults-Key für die zuletzt eingespielbare Seed-Version
    private static let seedVersionKey = "bundledExerciseSeedVersion"

    // Manuelle Versionsnummer — nur erhöhen wenn neue exercises_seed.json eingespielt wird
    static let currentSeedVersion: Int = 1

    // MARK: - Öffentlicher Einstiegspunkt

    /// Prüft ob ein Seed nötig ist und führt ihn ggf. durch
    static func seedIfNeeded(context: ModelContext) async {
        // Einmalige Bereinigung von Duplikaten vor dem Versions-Check
        await deduplicateIfNeeded(context: context)

        let lastVersion = UserDefaults.standard.integer(forKey: seedVersionKey)

        guard lastVersion < currentSeedVersion else {
            print("[BundledExerciseSeeder] Seed bereits aktuell (Version \(lastVersion)). Kein Seed nötig.")
            return
        }

        print("[BundledExerciseSeeder] Starte Seed von Version \(lastVersion) → \(currentSeedVersion)...")

        // Version optimistisch VOR dem Seed setzen — verhindert doppelten Durchlauf
        // bei konkurrierenden .task{}-Aufrufen (z.B. App im Hintergrund während Seed läuft)
        UserDefaults.standard.set(currentSeedVersion, forKey: seedVersionKey)

        do {
            try await performSeed(context: context)
            print("[BundledExerciseSeeder] Seed abgeschlossen. Version \(currentSeedVersion) gespeichert.")
        } catch {
            // Seed fehlgeschlagen → Version zurücksetzen damit nächster Start es erneut versucht
            UserDefaults.standard.set(lastVersion, forKey: seedVersionKey)
            print("[BundledExerciseSeeder] Seed fehlgeschlagen: \(error)")
        }
    }

    // MARK: - Duplikat-Bereinigung (läuft bei jedem Start)

    /// Bereinigt Duplikate die durch CloudKit-Sync + Seed-Race-Condition entstehen können.
    /// Läuft bei jedem App-Start — schnell genug (< 50ms) und vollständig idempotent.
    ///
    /// Fall 1: Mehrere Exercises mit gleicher apiID (CloudKit restored + Seed inserted)
    ///         → Behalte die mit den meisten Sets, lösche den Rest
    /// Fall 2: Exercise ohne apiID, aber gleicher Name wie eine Exercise mit apiID
    ///         → Lösche die ohne apiID (nur wenn keine Sets verknüpft)
    private static func deduplicateIfNeeded(context: ModelContext) async {
        do {
            let all = try context.fetch(FetchDescriptor<Exercise>())
            guard all.count > 0 else { return }

            var deleted = 0

            // --- Fall 1: apiID-Duplikate (gleiche UUID mehrfach) ---
            var byApiID: [UUID: [Exercise]] = [:]
            for ex in all {
                guard let apiID = ex.apiID else { continue }
                byApiID[apiID, default: []].append(ex)
            }

            for (_, duplicates) in byApiID where duplicates.count > 1 {
                // Behalte die Exercise mit den meisten verknüpften Sets
                let sorted = duplicates.sorted {
                    ($0.sets?.count ?? 0) > ($1.sets?.count ?? 0)
                }
                for toDelete in sorted.dropFirst() {
                    context.delete(toDelete)
                    deleted += 1
                }
            }

            // --- Fall 2: Name-Duplikate (ohne apiID, aber apiID-Version existiert) ---
            var withApiIDByName: [String: Exercise] = [:]
            for ex in all {
                guard ex.apiID != nil else { continue }
                let key = ex.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !key.isEmpty, withApiIDByName[key] == nil else { continue }
                withApiIDByName[key] = ex
            }

            for ex in all {
                guard ex.apiID == nil else { continue }
                let key = ex.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard withApiIDByName[key] != nil else { continue }
                guard (ex.sets?.isEmpty ?? true) else { continue }
                context.delete(ex)
                deleted += 1
            }

            // --- Fall 3: Mehrere Exercises OHNE apiID mit gleichem Namen ---
            // (z.B. ExerciseSeeder + CloudKit-Restore oder mehrfacher Import)
            // Behalte die mit den meisten Sets, lösche leere Duplikate (History schützen)
            var withoutApiIDByName: [String: [Exercise]] = [:]
            for ex in all {
                guard ex.apiID == nil else { continue }
                let key = ex.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !key.isEmpty else { continue }
                withoutApiIDByName[key, default: []].append(ex)
            }

            for (_, duplicates) in withoutApiIDByName where duplicates.count > 1 {
                let sorted = duplicates.sorted {
                    ($0.sets?.count ?? 0) > ($1.sets?.count ?? 0)
                }
                // Nur Duplikate ohne Sets löschen — Sets niemals entfernen (History-Schutz)
                for toDelete in sorted.dropFirst() {
                    guard (toDelete.sets?.isEmpty ?? true) else { continue }
                    context.delete(toDelete)
                    deleted += 1
                }
            }

            if deleted > 0 {
                try context.save()
                print("[BundledExerciseSeeder] Dedup: \(deleted) Duplikate bereinigt")
            }
        } catch {
            print("[BundledExerciseSeeder] Dedup fehlgeschlagen: \(error)")
        }
    }

    // MARK: - Seed-Durchführung

    /// Lädt exercises_seed.json und führt Upsert in SwiftData durch
    private static func performSeed(context: ModelContext) async throws {
        // JSON aus Bundle laden
        guard let url = Bundle.main.url(forResource: "exercises_seed", withExtension: "json") else {
            throw SeederError.bundleFileNotFound("exercises_seed.json")
        }

        let data = try Data(contentsOf: url)

        // Eigener Decoder — OHNE convertFromSnakeCase, da CodingKeys vorhanden
        let decoder = JSONDecoder()

        // Mikrosekunden-fähiger Datum-Decoder (z. B. "2026-01-11T13:44:38.729781+00:00")
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fmt.date(from: str) { return date }
            // Fallback ohne Fractional Seconds
            fmt.formatOptions = [.withInternetDateTime]
            if let date = fmt.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Ungültiges Datum: \(str)")
        }

        // Versuche zuerst das json_agg-Wrapper-Format (Supabase Dashboard Export)
        let supabaseExercises: [SupabaseExercise]
        if let containers = try? decoder.decode([JSONAggContainer].self, from: data),
           let first = containers.first {
            supabaseExercises = first.jsonAgg
        } else {
            // Fallback: direktes Array-Format
            supabaseExercises = try decoder.decode([SupabaseExercise].self, from: data)
        }

        print("[BundledExerciseSeeder] \(supabaseExercises.count) Exercises aus Bundle geladen.")

        // Alle bestehenden Exercises laden und als Dictionary aufbauen (apiID → Exercise)
        let fetchDescriptor = FetchDescriptor<Exercise>()
        let existingExercises = try context.fetch(fetchDescriptor)

        var localByApiID: [UUID: Exercise] = [:]
        for exercise in existingExercises {
            if let apiID = exercise.apiID {
                localByApiID[apiID] = exercise
            }
        }

        // Name-Fallback: Exercises OHNE apiID (z.B. von ExerciseSeeder) nach normalisiertem Namen indexieren (sicher bei Duplikaten)
        var localByName: [String: Exercise] = [:]
        for ex in existingExercises where ex.apiID == nil {
            let key = ex.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !key.isEmpty, localByName[key] == nil else { continue }
            localByName[key] = ex
        }

        var insertedCount = 0
        var updatedCount = 0
        var skippedCount = 0

        // Upsert in 50er-Batches
        for (index, supabaseExercise) in supabaseExercises.enumerated() {
            if let existing = localByApiID[supabaseExercise.id] {
                // apiID-Match: Update — Seed-Felder aktualisieren, User-Daten niemals anfassen
                let changed = updateExercise(existing, from: supabaseExercise)
                if changed { updatedCount += 1 } else { skippedCount += 1 }
            } else {
                // Name-Fallback: Exercise ohne apiID mit gleichem Namen adoptieren
                let nameKey = supabaseExercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if let existing = localByName[nameKey] {
                    // apiID setzen + Felder aktualisieren (kein Duplikat)
                    existing.apiID = supabaseExercise.id
                    let changed = updateExercise(existing, from: supabaseExercise)
                    if changed { updatedCount += 1 } else { skippedCount += 1 }
                } else {
                    // Wirklich neu: neues Exercise-Objekt anlegen
                    let newExercise = Exercise(from: supabaseExercise)
                    context.insert(newExercise)
                    insertedCount += 1
                }
            }

            // Batch-Save alle 50 Items
            if (index + 1) % 50 == 0 {
                try context.save()
            }
        }

        // Abschließendes Save für verbleibende Einträge
        try context.save()

        print("[BundledExerciseSeeder] Ergebnis — Inserted: \(insertedCount), Updated: \(updatedCount), Skipped: \(skippedCount)")
    }

    // MARK: - Update-Logik

    /// Aktualisiert nur Seed-relevante Felder — User-Daten werden NIEMALS berührt
    @discardableResult
    private static func updateExercise(_ existing: Exercise, from source: SupabaseExercise) -> Bool {
        var changed = false

        // Name
        if existing.name != source.name {
            existing.name = source.name
            changed = true
        }

        // Anweisungen (instructions)
        let newInstructions = source.instructions ?? ""
        if existing.instructions != newInstructions {
            existing.instructions = newInstructions
            changed = true
        }

        // Beschreibung (tips → exerciseDescription)
        let newDescription = source.tips ?? ""
        if existing.exerciseDescription != newDescription {
            existing.exerciseDescription = newDescription
            changed = true
        }

        // Video-Pfad
        if existing.videoPath != source.videoPath {
            existing.videoPath = source.videoPath
            changed = true
        }

        // Poster-Pfad
        if existing.posterPath != source.posterPath {
            existing.posterPath = source.posterPath
            changed = true
        }

        // Feingranulare Primärmuskeln
        let newPrimaryRaw = source.primaryMuscles
            .compactMap { MuscleGroupMapper.mapDetailed(supabaseValue: $0) }
            .map { $0.rawValue }
        if existing.detailedPrimaryMusclesRaw != newPrimaryRaw {
            existing.detailedPrimaryMuscles = source.primaryMuscles
                .compactMap { MuscleGroupMapper.mapDetailed(supabaseValue: $0) }
            changed = true
        }

        // Feingranulare Sekundärmuskeln
        let newSecondaryRaw = source.secondaryMuscles
            .compactMap { MuscleGroupMapper.mapDetailed(supabaseValue: $0) }
            .map { $0.rawValue }
        if existing.detailedSecondaryMusclesRaw != newSecondaryRaw {
            existing.detailedSecondaryMuscles = source.secondaryMuscles
                .compactMap { MuscleGroupMapper.mapDetailed(supabaseValue: $0) }
            changed = true
        }

        // Equipment
        let newEquipment = ExerciseEquipment.fromSupabase(source.equipment.first)
        if existing.equipment != newEquipment {
            existing.equipment = newEquipment
            changed = true
        }

        // Schwierigkeitsgrad
        let newDifficulty = ExerciseDifficulty.fromSupabase(source.difficulty ?? "intermediate")
        if existing.difficulty != newDifficulty {
            existing.difficulty = newDifficulty
            changed = true
        }

        // Kategorie
        let newCategory = ExerciseCategory.fromSupabase(
            mechanic: source.mechanicType,
            force: source.forceType
        )
        if existing.category != newCategory {
            existing.category = newCategory
            changed = true
        }

        // NIEMALS anfassen:
        // isFavorite, isCustom, isArchived, repRangeMin, repRangeMax,
        // progressionStep, targetRIR, sets, localVideoFileName, sortIndex, lastProgressionDate

        return changed
    }
}

// MARK: - Hilfswrapper

/// Wrapper für Supabase Dashboard JSON-Export (json_agg-Format)
private struct JSONAggContainer: Decodable {
    let jsonAgg: [SupabaseExercise]
    enum CodingKeys: String, CodingKey { case jsonAgg = "json_agg" }
}

// MARK: - Fehlertypen

private enum SeederError: LocalizedError {
    case bundleFileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .bundleFileNotFound(let name):
            return "exercises_seed.json nicht im App-Bundle gefunden: \(name)"
        }
    }
}
