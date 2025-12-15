//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : WorkoutEntry.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 15.12.2025                                                       /
// Beschreibung  : Trainingsblock innerhalb einer WorkoutSession                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Enums für dieses Model findet man im File WorkoutTypes.swift      /
//                Die UI-Ausgabe dieser Enums im File TypesUI.swift                 /
//                Die formatierten Werte aus dem Model sind in SessionUI            /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import Foundation

@Model
final class WorkoutEntry {

    // MARK: Beziehung zur Session

    // Übergeordnete WorkoutSession
    var session: WorkoutSession?

    // MARK: - Typ des Trainingblocks

    // Persistenter Rohwert für den Entry-Typen
    var kindRaw: Int = WorkoutEntryKind.cardio.rawValue

    // Typisierter Zugriff auf den Trainingsblock-Typen
    var kind: WorkoutEntryKind {
        get { WorkoutEntryKind(rawValue: kindRaw) ?? .cardio }
        set { kindRaw = newValue.rawValue }
    }

    // MARK: Allgemeine Trainingsdaten

    // Anzeigename des Trainingsblocks
    var title: String = " "

    // Start- und Endzeitpunkt des Trainingsblocks
    var startedAt: Date?
    var endedAt: Date?

    // Dauer des Trainingsblocks (in Sekunden ohne Pausen)
    var activeDurationSeconds: Int = 0

    // MARK: - Übung

    // Referenzierte Übung (vor allem für Krafttraining relevant)
    var exercise: Exercise?

    // MARK: - Krafttraining: Sätze

    // Sätze für Krafttraining (nur sinnvoll bei kind == .strength)
    @Relationship(deleteRule: .cascade, inverse: \StrengthSet.entry)
    var sets: [StrengthSet]?

    // MARK: Initialisierung

    init(kind: WorkoutEntryKind, title: String) {
        self.kindRaw = kind.rawValue
        self.title = title
    }
}
