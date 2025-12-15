//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : WorkoutSessionEntries.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 15.12.2025                                                       /
// Beschreibung  : Helper-Funktion für WorkoutSession                               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import Foundation

extension WorkoutSession {

    // Liefert immer eine Liste von Entries (nie nil).
    var safeEntries: [WorkoutEntry] {
        entries ?? []
    }

    // Fügt einen Entry hinzu und setzt die Gegenbeziehung sauber.
    func addEntry(_ entry: WorkoutEntry) {
        if entries == nil { entries = [] }
        entries?.append(entry)
        entry.session = self
    }

    // Entfernt einen Entry (wenn vorhanden).
    func removeEntry(_ entry: WorkoutEntry) {
        entries?.removeAll { $0 === entry }
        if entries?.isEmpty == true { entries = nil }
    }
}
