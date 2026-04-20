//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Widget                                                /
// Datei . . . . : WidgetDataStore.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : AppGroup-basierter Schreib-Helfer für Widget-Snapshots           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Das App-Target schreibt, das Widget-Extension-Target liest.       /
//                Read-Implementierung: MotionCoreWidgets/Shared/WidgetDataStore.swift /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Widget Data Store (App Target)

/// Schreibt WidgetSnapshot-Daten in den AppGroup-Container.
/// Nur das App-Target (Main App) schreibt — die Widget Extension liest.
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
}
