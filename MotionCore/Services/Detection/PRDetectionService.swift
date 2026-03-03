//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Erkennung                                                        /
// Datei . . . . : PRDetectionService.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : Erkennt persönliche Bestleistungen via Epley-1RM-Formel          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct PRDetectionService {

    // MARK: - Input

    let historicalSessions: [StrengthSession]

    // MARK: - Öffentliche API

    /// Gibt true zurück, wenn `set` einen neuen 1RM-PR darstellt.
    /// Nur work-Sätze mit weight > 0 und reps > 0 werden berücksichtigt.
    func isNewPR(set: ExerciseSet) -> Bool {
        guard set.setKind == .work, set.weight > 0, set.reps > 0 else { return false }
        let current = epley(weight: set.weight, reps: set.reps)
        return current > bestOneRM(for: set.exerciseName)
    }

    /// Berechnet den 1RM-Wert für einen gegebenen Satz via Epley-Formel.
    func calculatedOneRM(for set: ExerciseSet) -> Double {
        epley(weight: set.weight, reps: set.reps)
    }

    /// Bisheriger Bestwert (1RM) für eine Übung aus historischen Sessions.
    func bestOneRM(for exerciseName: String) -> Double {
        historicalSessions
            .flatMap { $0.safeExerciseSets }
            .filter {
                $0.exerciseName == exerciseName
                    && $0.setKind == .work
                    && $0.weight > 0
                    && $0.reps > 0
                    && $0.isCompleted
            }
            .map { epley(weight: $0.weight, reps: $0.reps) }
            .max() ?? 0
    }

    // MARK: - Privat

    private func epley(weight: Double, reps: Int) -> Double {
        weight * (1.0 + Double(reps) / 30.0)
    }
}
