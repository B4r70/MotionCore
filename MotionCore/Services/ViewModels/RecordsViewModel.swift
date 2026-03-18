//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : ViewModels                                                       /
// Datei . . . . : RecordsViewModel.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-18                                                       /
// Beschreibung  : Gecachte Rekord-Daten — berechnet einmal, O(1) lesbar.          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import Observation

@Observable
final class RecordsViewModel {

    // MARK: - Gecachte Kraft-Rekorde

    private(set) var highestVolumeSession: StrengthRecord? = nil
    private(set) var mostSetsSession: StrengthRecord? = nil
    private(set) var mostRepsSession: StrengthRecord? = nil
    private(set) var heaviestSingleSet: StrengthRecord? = nil
    private(set) var longestStrengthSession: StrengthRecord? = nil
    private(set) var mostExercisesSession: StrengthRecord? = nil
    private(set) var highestEstimated1RM: StrengthRecord? = nil

    // MARK: - Gecachte Cardio-Rekorde

    private(set) var longestDistanceWorkout: CardioSession? = nil
    private(set) var highestBurnedCaloriesWorkout: CardioSession? = nil

    // MARK: - Neuberechnung

    /// Berechnet alle Kraft-Rekorde neu.
    /// Aufrufen bei Änderung von allStrengthSessions.
    func recalculateStrength(sessions: [StrengthSession]) {
        let engine = StrengthRecordCalcEngine(sessions: sessions)
        self.highestVolumeSession = engine.highestVolumeSession
        self.mostSetsSession = engine.mostSetsSession
        self.mostRepsSession = engine.mostRepsSession
        self.heaviestSingleSet = engine.heaviestSingleSet
        self.longestStrengthSession = engine.longestStrengthSession
        self.mostExercisesSession = engine.mostExercisesSession
        self.highestEstimated1RM = engine.highestEstimated1RM
    }

    /// Berechnet alle Cardio-Rekorde neu.
    /// Aufrufen bei Änderung von allCardioSessions.
    func recalculateCardio(sessions: [CardioSession]) {
        let engine = RecordCalcEngine(workouts: sessions)
        self.longestDistanceWorkout = engine.longestDistanceWorkout
        self.highestBurnedCaloriesWorkout = engine.highestBurnedCaloriesWorkout
    }
}
