//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Widget Shared                                                    /
// Datei . . . . : WidgetDataStore.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               //
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : AppGroup-basierter Lese-/Schreib-Helfer für Widget-Snapshots     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Widget Data Store

/// Liest und schreibt WidgetSnapshot-Daten über den AppGroup-Container.
/// Beide Targets (App + Widget Extension) nutzen denselben Speicherort.
struct WidgetDataStore {

    // MARK: - Konstanten

    static let appGroup = "group.com.barto.motioncore"
    private static let snapshotFileName = "widget_snapshot.json"

    // MARK: - Container-URL

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }

    private static var snapshotFileURL: URL? {
        containerURL?.appendingPathComponent(snapshotFileName)
    }

    // MARK: - Schreiben

    /// Speichert einen WidgetSnapshot als JSON in den AppGroup-Container.
    /// Wird ausschliesslich von der Main App aufgerufen.
    static func write(snapshot: WidgetSnapshot) {
        guard let url = snapshotFileURL else {
            print("WidgetDataStore: AppGroup-Container nicht verfügbar")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            let data = try encoder.encode(snapshot)
            try data.write(to: url, options: .atomic)
        } catch {
            print("WidgetDataStore: Fehler beim Schreiben — \(error)")
        }
    }

    // MARK: - Lesen

    /// Liest den gespeicherten WidgetSnapshot aus dem AppGroup-Container.
    /// Gibt `WidgetSnapshot.placeholder` zurück wenn keine Daten vorhanden sind.
    static func readSnapshot() -> WidgetSnapshot {
        guard let url = snapshotFileURL,
              let data = try? Data(contentsOf: url) else {
            return .placeholder
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            return try decoder.decode(WidgetSnapshot.self, from: data)
        } catch {
            print("WidgetDataStore: Fehler beim Lesen — \(error)")
            return .placeholder
        }
    }
}
