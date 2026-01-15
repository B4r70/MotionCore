//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : TrainingEntry.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.12.2025                                                       /
// Beschreibung  : Einzelner Eintrag in einem Trainingsplan                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class TrainingEntry {
    // MARK: - Grunddaten

    var scheduledDate: Date = Date()        // Geplantes Datum
    var isCompleted: Bool = false           // Wurde durchgeführt?
    var notes: String = ""                  // Notizen für diesen Eintrag

    // MARK: - Persistente ENUM-Rohwerte

    var workoutTypeRaw: String = "cardio"   // "cardio", "strength", "outdoor"

    // MARK: - Typisierte ENUM-Property

    var workoutType: WorkoutType {
        get { WorkoutType(rawValue: workoutTypeRaw) ?? .cardio }
        set { workoutTypeRaw = newValue.rawValue }
    }

    // MARK: - Beziehungen

    @Relationship(inverse: \TrainingPlan.entries)
    var plan: TrainingPlan?                // Gehört zu welchem Plan?

    // Optional: Referenzen zu durchgeführten Sessions (als IDs)
    var completedCardioSessionID: String?
    var completedStrengthSessionID: String?
    var completedOutdoorSessionID: String?

    // MARK: - Berechnete Werte

    // Datum liegt in der Vergangenheit?
    var isPastDue: Bool {
        scheduledDate < Date()
    }

    // Wurde verpasst (überfällig und nicht erledigt)?
    var isMissed: Bool {
        isPastDue && !isCompleted
    }

    // MARK: - Initialisierung (WICHTIG für SwiftData!)

    init(
        scheduledDate: Date = Date(),
        workoutType: WorkoutType = .cardio,
        notes: String = "",
        isCompleted: Bool = false
    ) {
        self.scheduledDate = scheduledDate
        self.workoutTypeRaw = workoutType.rawValue
        self.notes = notes
        self.isCompleted = isCompleted
    }
}

