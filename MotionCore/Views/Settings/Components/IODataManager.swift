//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Datenmanagement                                                  /
// Datei . . . . : IODataManager.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.11.2025                                                       /
// Beschreibung  : Import- und Exportmanagement                                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

/// Verwaltet die Import- und Exportfunktionen für Workout-Daten.
/// (Der korrekte Klassenname lautet IODataManager)
final class IODataManager {

    // MARK: - Export

    /// Führt den Export aller Workout-Daten durch, speichert sie temporär als JSON
    /// und gibt die URL zur Freigabe zurück.
    /// - Parameter context: Der ModelContext, um alle Workouts abzurufen.
    /// - Returns: Die temporäre URL zur exportierten JSON-Datei.
    func exportWorkouts(context: ModelContext) throws -> URL {
        // 1. Daten abrufen
        let descriptor = FetchDescriptor<CardioSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let allWorkouts = try context.fetch(descriptor)

        guard !allWorkouts.isEmpty else {
            // Wenn keine Daten vorhanden sind, werfen wir einen Fehler
            throw DataIOError.noDataToExport
        }

        // 2. Export-Paket erstellen
        let pkg = WorkoutExportPackage(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: .now),
            items: allWorkouts.map { $0.exportItem }
        )

        // 3. Kodierung
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(pkg)

        // 4. Temporäre Datei erstellen und schreiben
        let filename = "MotionCore-Export-\(Int(Date().timeIntervalSince1970)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)

        return url
    }

        /// Exportiert alle Übungen als JSON-Datei
        /// - Parameter context: Der ModelContext, um alle Exercises abzurufen
        /// - Returns: Die temporäre URL zur exportierten JSON-Datei
    func exportExercises(context: ModelContext) throws -> URL {
            // 1. Daten abrufen
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name, order: .forward)])
        let allExercises = try context.fetch(descriptor)

        guard !allExercises.isEmpty else {
            throw DataIOError.noDataToExport
        }

            // 2. Export-Paket erstellen
        let pkg = ExerciseExportPackage(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: .now),
            items: allExercises.map { $0.exportItem }
        )

            // 3. Kodierung
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(pkg)

            // 4. Temporäre Datei erstellen
        let filename = "MotionCore-Exercises-\(Int(Date().timeIntervalSince1970)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)

        return url
    }

    // MARK: - Import

    /// Führt den Import von Workout-Daten aus einer gegebenen URL durch.
    /// - Parameter context: Der ModelContext, in dem die Daten gespeichert werden sollen.
    /// - Parameter url: Die URL der zu importierenden JSON-Datei.
    /// - Returns: Die Anzahl der erfolgreich importierten Workouts.
    func importWorkouts(context: ModelContext, url: URL) throws -> Int {
        // Sicherstellen, dass die Datei zugänglich ist
        guard url.startAccessingSecurityScopedResource() else {
            throw DataIOError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // 1. Daten lesen
        let data = try Data(contentsOf: url)

        // 2. Dekodierung
        let decoder = JSONDecoder()
        let pkg = try decoder.decode(WorkoutExportPackage.self, from: data)

        guard pkg.version == 1 else {
            throw DataIOError.unsupportedVersion
        }

        var importedCount = 0

        // 3. Speichern der Workouts im ModelContext
        for exportItem in pkg.items {
            let workout = CardioSession.fromExportItem(exportItem)
            context.insert(workout)
            importedCount += 1
        }

        // 4. Speichern des Contexts
        try context.save()

        return importedCount
    }

    /// Importiert Übungen aus einer JSON-Datei
    /// - Parameters:
    ///   - context: Der ModelContext
    ///   - url: Die URL der JSON-Datei
    /// - Returns: Anzahl der importierten Übungen
    func importExercises(context: ModelContext, url: URL) throws -> Int {
            // Sicherstellen, dass die Datei zugänglich ist
        guard url.startAccessingSecurityScopedResource() else {
            throw DataIOError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

            // 1. Daten lesen
        let data = try Data(contentsOf: url)

            // 2. Dekodierung
        let decoder = JSONDecoder()
        let pkg = try decoder.decode(ExerciseExportPackage.self, from: data)

        guard pkg.version == 1 else {
            throw DataIOError.unsupportedVersion
        }

        var importedCount = 0

            // 3. Speichern der Exercises im ModelContext
        for exportItem in pkg.items {
            let exercise = Exercise.fromExportItem(exportItem)
            context.insert(exercise)
            importedCount += 1
        }

            // 4. Speichern
        try context.save()

        return importedCount
    }

        /// Löscht alle gespeicherten WorkoutSession-Objekte aus dem ModelContext.
        /// - Parameter context: Der ModelContext, aus dem die Daten gelöscht werden sollen.
        /// - Throws: Einen Fehler, falls die Operation fehlschlägt.
    func deleteAllWorkouts(context: ModelContext) throws -> Int {

            // 1. Alle Objekte vom Typ WorkoutSession abrufen
            // Wir benötigen keine Sortierung, nur die Objekte selbst.
        let workoutsToDelete = try context.fetch(FetchDescriptor<CardioSession>())

        let deletedCount = workoutsToDelete.count

            // 2. Alle Workouts löschen
        for workout in workoutsToDelete {
            context.delete(workout)
        }

            // 3. Ã„nderungen speichern, um die Löschung zu persistieren
        try context.save()

        return deletedCount // Gibt die Anzahl der gelöschten Elemente zurück
    }

    // MARK: - TrainingPlan Export/Import

    /// Exportiert alle Trainingspläne als JSON-Datei
    /// - Parameter context: Der ModelContext, um alle TrainingPlans abzurufen
    /// - Returns: Die temporäre URL zur exportierten JSON-Datei
    func exportTrainingPlans(context: ModelContext) throws -> URL {
        // 1. Daten abrufen
        let descriptor = FetchDescriptor<TrainingPlan>(sortBy: [SortDescriptor(\.title, order: .forward)])
        let allPlans = try context.fetch(descriptor)

        guard !allPlans.isEmpty else {
            throw DataIOError.noDataToExport
        }

        // 2. Export-Paket erstellen
        let pkg = TrainingPlanExportPackage(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: .now),
            items: allPlans.map { $0.exportItem }
        )

        // 3. Kodierung
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(pkg)

        // 4. Temporäre Datei erstellen
        let filename = "MotionCore-TrainingPlans-\(Int(Date().timeIntervalSince1970)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)

        return url
    }

    /// Importiert Trainingspläne aus einer JSON-Datei
    /// - Parameters:
    ///   - context: Der ModelContext
    ///   - url: Die URL der JSON-Datei
    /// - Returns: Anzahl der importierten Trainingspläne
    func importTrainingPlans(context: ModelContext, url: URL) throws -> Int {
        // Sicherstellen, dass die Datei zugänglich ist
        guard url.startAccessingSecurityScopedResource() else {
            throw DataIOError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // 1. Daten lesen
        let data = try Data(contentsOf: url)

        // 2. Dekodierung
        let decoder = JSONDecoder()
        let pkg = try decoder.decode(TrainingPlanExportPackage.self, from: data)

        guard pkg.version == 1 else {
            throw DataIOError.unsupportedVersion
        }

        var importedCount = 0

        // 3. Speichern der TrainingPlans im ModelContext
        for exportItem in pkg.items {
            let plan = TrainingPlan.fromExportItem(exportItem)
            context.insert(plan)

            // Template-Sets sind bereits verknüpft, müssen aber auch eingefügt werden
            for templateSet in plan.templateSets {
                context.insert(templateSet)
            }

            importedCount += 1
        }

        // 4. Speichern
        try context.save()

        return importedCount
    }

    // MARK: - ExerciseSet Export/Import (standalone)

    /// Exportiert alle ExerciseSets als JSON-Datei
    /// - Parameter context: Der ModelContext, um alle ExerciseSets abzurufen
    /// - Returns: Die temporäre URL zur exportierten JSON-Datei
    func exportExerciseSets(context: ModelContext) throws -> URL {
        // 1. Daten abrufen
        let descriptor = FetchDescriptor<ExerciseSet>(sortBy: [SortDescriptor(\.exerciseName, order: .forward)])
        let allSets = try context.fetch(descriptor)

        guard !allSets.isEmpty else {
            throw DataIOError.noDataToExport
        }

        // 2. Export-Paket erstellen
        let pkg = ExerciseSetExportPackage(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: .now),
            items: allSets.map { $0.exportItem }
        )

        // 3. Kodierung
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(pkg)

        // 4. Temporäre Datei erstellen
        let filename = "MotionCore-ExerciseSets-\(Int(Date().timeIntervalSince1970)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)

        return url
    }

    /// Importiert ExerciseSets aus einer JSON-Datei
    /// - Parameters:
    ///   - context: Der ModelContext
    ///   - url: Die URL der JSON-Datei
    /// - Returns: Anzahl der importierten ExerciseSets
    func importExerciseSets(context: ModelContext, url: URL) throws -> Int {
        // Sicherstellen, dass die Datei zugänglich ist
        guard url.startAccessingSecurityScopedResource() else {
            throw DataIOError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // 1. Daten lesen
        let data = try Data(contentsOf: url)

        // 2. Dekodierung
        let decoder = JSONDecoder()
        let pkg = try decoder.decode(ExerciseSetExportPackage.self, from: data)

        guard pkg.version == 1 else {
            throw DataIOError.unsupportedVersion
        }

        var importedCount = 0

        // 3. Speichern der ExerciseSets im ModelContext
        for exportItem in pkg.items {
            let exerciseSet = ExerciseSet.fromExportItem(exportItem)
            context.insert(exerciseSet)
            importedCount += 1
        }

        // 4. Speichern
        try context.save()

        return importedCount
    }

    // MARK: - StrengthSession Export/Import

    /// Exportiert alle Krafttrainings als JSON-Datei
    /// - Parameter context: Der ModelContext, um alle StrengthSessions abzurufen
    /// - Returns: Die temporäre URL zur exportierten JSON-Datei
    func exportStrengthSessions(context: ModelContext) throws -> URL {
        // 1. Daten abrufen
        let descriptor = FetchDescriptor<StrengthSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let allSessions = try context.fetch(descriptor)

        guard !allSessions.isEmpty else {
            throw DataIOError.noDataToExport
        }

        // 2. Export-Paket erstellen
        let pkg = StrengthSessionExportPackage(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: .now),
            items: allSessions.map { $0.exportItem }
        )

        // 3. Kodierung
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(pkg)

        // 4. Temporäre Datei erstellen
        let filename = "MotionCore-StrengthSessions-\(Int(Date().timeIntervalSince1970)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)

        return url
    }

    /// Importiert Krafttrainings aus einer JSON-Datei
    /// - Parameters:
    ///   - context: Der ModelContext
    ///   - url: Die URL der JSON-Datei
    /// - Returns: Anzahl der importierten StrengthSessions
    func importStrengthSessions(context: ModelContext, url: URL) throws -> Int {
        // Sicherstellen, dass die Datei zugänglich ist
        guard url.startAccessingSecurityScopedResource() else {
            throw DataIOError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // 1. Daten lesen
        let data = try Data(contentsOf: url)

        // 2. Dekodierung
        let decoder = JSONDecoder()
        let pkg = try decoder.decode(StrengthSessionExportPackage.self, from: data)

        guard pkg.version == 1 else {
            throw DataIOError.unsupportedVersion
        }

        var importedCount = 0

        // 3. Speichern der StrengthSessions im ModelContext
        for exportItem in pkg.items {
            let session = StrengthSession.fromExportItem(exportItem)
            context.insert(session)

            // ExerciseSets sind bereits verknüpft, müssen aber auch eingefügt werden
            for exerciseSet in session.exerciseSets {
                context.insert(exerciseSet)
            }

            importedCount += 1
        }

        // 4. Speichern
        try context.save()

        return importedCount
    }
}

// MARK: - Fehlerbehandlung
enum DataIOError: LocalizedError {
    case noDataToExport
    case accessDenied
    case importFailed
    case unsupportedVersion
    case deleteError(Error)
    case generalError(Error)

    var errorDescription: String? {
        switch self {
            case .noDataToExport:
                return "Es sind keine Workouts zum Exportieren vorhanden."
            case .accessDenied:
                return "Zugriff auf die ausgewählte Datei verweigert."
            case .importFailed:
                return "Der Importvorgang ist fehlgeschlagen."
            case .unsupportedVersion:
                return "Das Format der Datei wird von dieser App-Version nicht unterstützt."
            case .deleteError(let error): // <-- NEU
                return "Löschen fehlgeschlagen: \(error.localizedDescription)"
            case .generalError(let error):
                return "Ein allgemeiner Fehler ist aufgetreten: \(error.localizedDescription)"
        }
    }
}

func deleteAllWorkouts(context: ModelContext) throws -> Int {

    // Wir nutzen einen do-catch-Block innerhalb der Funktion,
    // um generische Fehler in unseren spezifischen Fehler zu verpacken.
    do {
        let workoutsToDelete = try context.fetch(FetchDescriptor<CardioSession>())
        let deletedCount = workoutsToDelete.count

        for workout in workoutsToDelete {
            context.delete(workout)
        }

        try context.save()

        return deletedCount
    } catch {
        // Jeden Fehler, der während des Fetches oder Speicherns auftritt,
        // verpacken wir in den neuen DataIOError.deleteError.
        throw DataIOError.deleteError(error)
    }
}

extension IODataManager {

    // Generic helper: delete all objects of a given SwiftData model type
    @discardableResult
    private func deleteAll<T: PersistentModel>(_ type: T.Type, context: ModelContext) throws -> Int {
        do {
            let items = try context.fetch(FetchDescriptor<T>())
            let count = items.count

            for item in items {
                context.delete(item)
            }

            try context.save()
            return count
        } catch {
            throw DataIOError.deleteError(error)
        }
    }

    // MARK: - Strength data deletes

    func deleteAllExercises(context: ModelContext) throws -> Int {
        try deleteAll(Exercise.self, context: context)
    }

    func deleteAllExerciseSets(context: ModelContext) throws -> Int {
        try deleteAll(ExerciseSet.self, context: context)
    }

    func deleteAllTrainingPlans(context: ModelContext) throws -> Int {
        try deleteAll(TrainingPlan.self, context: context)
    }

    func deleteAllStrengthSessions(context: ModelContext) throws -> Int {
        try deleteAll(StrengthSession.self, context: context)
    }

    /// Convenience: delete all strength-related data in a safe-ish order.
    /// (Parents first if they cascade; otherwise this still usually works with optional relationships.)
    func deleteAllStrengthData(context: ModelContext) throws -> (sessions: Int, plans: Int, sets: Int, exercises: Int) {
        let sessions = try deleteAllStrengthSessions(context: context)
        let plans = try deleteAllTrainingPlans(context: context)
        let sets = try deleteAllExerciseSets(context: context)
        let exercises = try deleteAllExercises(context: context)
        return (sessions, plans, sets, exercises)
    }
}
