//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : ExerciseProgressionState.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Persistenter Progressions-Zustand pro Übung                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Alle Properties haben Defaults → CloudKit-kompatibel              /
//                Match via exerciseGroupKey (wie ExerciseRating) — keine           /
//                @Relationship zu Exercise, um Many-to-One-Zwang zu vermeiden.     /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class ExerciseProgressionState {

    // MARK: - Identifikation

    var id: UUID = UUID()

    // MARK: - Übungs-Referenz

    // Stabiler Schlüssel der Übungsgruppe (entspricht ExerciseSet.groupKey)
    var exerciseGroupKey: String = ""

    // MARK: - Arbeitsgewicht

    // Aktuelles Arbeitsgewicht, wird bei jeder Progression aktualisiert
    var workingWeight: Double = 0.0

    // Für Rollback-Wiederherstellung gespeichertes vorheriges Arbeitsgewicht
    var previousWorkingWeight: Double?

    // MARK: - Ziel-Reps

    var targetReps: Int = 10
    var minTargetReps: Int = 8
    var maxTargetReps: Int = 12

    // MARK: - Progressions-Modus

    // Rohwert für CloudKit-Kompatibilität (String statt Enum)
    var progressionModeRaw: String = "smart"

    // MARK: - Historie

    var lastProgressionDate: Date?
    var lastRollbackDate: Date?
    var consecutiveSuccessCount: Int = 0
    var consecutiveFailCount: Int = 0
    var isActive: Bool = true

    // MARK: - Auto-Progression (Phase 1.5)

    var lastAutoProgressionDate: Date?
    var lastAutoProgressionAmount: Double?
    var autoProgressionUndoable: Bool = false

    // MARK: - Metadaten

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Typisierter Modus (computed)

    // Gibt den typisierten Progressions-Modus zurück, Fallback auf .smart
    var progressionMode: ProgressionMode {
        get { ProgressionMode(rawValue: progressionModeRaw) ?? .smart }
        set { progressionModeRaw = newValue.rawValue }
    }

    // MARK: - Initialisierung

    init(exerciseGroupKey: String = "", workingWeight: Double = 0.0) {
        self.exerciseGroupKey = exerciseGroupKey
        self.workingWeight = workingWeight
    }
}
