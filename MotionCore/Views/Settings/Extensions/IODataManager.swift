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
        let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let allWorkouts = try context.fetch(descriptor)

        guard !allWorkouts.isEmpty else {
            // Wenn keine Daten vorhanden sind, werfen wir einen Fehler
            throw DataIOError.noDataToExport
        }

        // 2. Export-Paket erstellen
        let pkg = ExportPackage(
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
        let pkg = try decoder.decode(ExportPackage.self, from: data)

        guard pkg.version == 1 else {
            throw DataIOError.unsupportedVersion
        }

        var importedCount = 0

        // 3. Speichern der Workouts im ModelContext
        for exportItem in pkg.items {
            let workout = WorkoutSession.fromExportItem(exportItem)
            context.insert(workout)
            importedCount += 1
        }

        // 4. Speichern des Contexts
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
        case .generalError(let error):
            return "Ein allgemeiner Fehler ist aufgetreten: \(error.localizedDescription)"
        }
    }
}
