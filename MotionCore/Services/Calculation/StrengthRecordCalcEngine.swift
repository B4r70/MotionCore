//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Rekorde                                                          /
// Datei . . . . : StrengthRecordCalcEngine.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-17                                                       /
// Beschreibung  : Berechnungen für Kraft-spezifische Rekorde                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Kraft-Rekord Struct

/// Repräsentiert einen Kraft-Rekord mit Session-Referenz und aufbereitetem Anzeigewert.
struct StrengthRecord {
    /// Die Session, in der der Rekord erzielt wurde.
    let session: StrengthSession
    /// Übungsname — nur bei Set-Level-Rekorden (Einzelsatz, geschätztes 1RM).
    let exerciseName: String?
    /// Rohwert für interne Vergleiche.
    let value: Double
    /// Formatierter Wert für die Anzeige in der UI.
    let formattedValue: String
}

// MARK: - StrengthRecordCalcEngine

struct StrengthRecordCalcEngine {

    // MARK: - Input

    let sessions: [StrengthSession]

    // MARK: - Initializer

    init(sessions: [StrengthSession]) {
        self.sessions = sessions
    }

    // MARK: - Interne Hilfsmethode

    /// Alle abgeschlossenen Sets mit Rückbezug auf die jeweilige Session.
    private var allSets: [(set: ExerciseSet, session: StrengthSession)] {
        sessions.flatMap { session in
            session.safeExerciseSets.map { (set: $0, session: session) }
        }
    }

    // MARK: - Session-Level Rekorde

    /// Session mit dem höchsten Gesamtvolumen (Gewicht × Wiederholungen).
    var highestVolumeSession: StrengthRecord? {
        guard let session = sessions.max(by: { $0.totalVolume < $1.totalVolume }),
              session.totalVolume > 0 else { return nil }
        let vol = session.totalVolume
        let formatted = vol >= 1000
            ? String(format: "%.2f t", vol / 1000.0)
            : String(format: "%.0f kg", vol)
        return StrengthRecord(
            session: session,
            exerciseName: nil,
            value: vol,
            formattedValue: formatted
        )
    }

    /// Session mit den meisten abgeschlossenen Sätzen.
    var mostSetsSession: StrengthRecord? {
        guard let session = sessions.max(by: { $0.totalSets < $1.totalSets }),
              session.totalSets > 0 else { return nil }
        return StrengthRecord(
            session: session,
            exerciseName: nil,
            value: Double(session.totalSets),
            formattedValue: "\(session.totalSets) Sätze"
        )
    }

    /// Session mit den meisten Gesamtwiederholungen über alle Sets.
    var mostRepsSession: StrengthRecord? {
        let sessionsWithReps = sessions.map { session -> (session: StrengthSession, reps: Int) in
            let total = session.safeExerciseSets.reduce(0) { $0 + $1.reps }
            return (session: session, reps: total)
        }
        guard let best = sessionsWithReps.max(by: { $0.reps < $1.reps }),
              best.reps > 0 else { return nil }
        return StrengthRecord(
            session: best.session,
            exerciseName: nil,
            value: Double(best.reps),
            formattedValue: "\(best.reps) Reps"
        )
    }

    /// Session mit der längsten Trainingsdauer in Minuten.
    var longestStrengthSession: StrengthRecord? {
        guard let session = sessions.max(by: { $0.duration < $1.duration }),
              session.duration > 0 else { return nil }
        return StrengthRecord(
            session: session,
            exerciseName: nil,
            value: Double(session.duration),
            formattedValue: "\(session.duration) min"
        )
    }

    /// Session mit den meisten unterschiedlichen Übungen.
    var mostExercisesSession: StrengthRecord? {
        guard let session = sessions.max(by: { $0.exercisesPerformed < $1.exercisesPerformed }),
              session.exercisesPerformed > 0 else { return nil }
        return StrengthRecord(
            session: session,
            exerciseName: nil,
            value: Double(session.exercisesPerformed),
            formattedValue: "\(session.exercisesPerformed) Übungen"
        )
    }

    // MARK: - Set-Level Rekorde

    /// Schwerster abgeschlossener Einzelsatz (höchstes Gewicht).
    var heaviestSingleSet: StrengthRecord? {
        let completed = allSets.filter { $0.set.isCompleted && $0.set.weight > 0 }
        guard let best = completed.max(by: { $0.set.weight < $1.set.weight }) else { return nil }
        let name = best.set.exerciseNameSnapshot.isEmpty
            ? best.set.exerciseName
            : best.set.exerciseNameSnapshot
        return StrengthRecord(
            session: best.session,
            exerciseName: name.isEmpty ? nil : name,
            value: best.set.weight,
            formattedValue: String(format: "%.1f kg", best.set.weight)
        )
    }

    /// Höchstes geschätztes 1RM über alle Sets (Epley-Formel: weight × (1 + reps / 30)).
    var highestEstimated1RM: StrengthRecord? {
        let valid = allSets.filter {
            $0.set.isCompleted && $0.set.weight > 0 && $0.set.reps > 0
        }
        guard let best = valid.max(by: {
            $0.set.weight * (1.0 + Double($0.set.reps) / 30.0) <
            $1.set.weight * (1.0 + Double($1.set.reps) / 30.0)
        }) else { return nil }
        let oneRM = best.set.weight * (1.0 + Double(best.set.reps) / 30.0)
        let name = best.set.exerciseNameSnapshot.isEmpty
            ? best.set.exerciseName
            : best.set.exerciseNameSnapshot
        return StrengthRecord(
            session: best.session,
            exerciseName: name.isEmpty ? nil : name,
            value: oneRM,
            formattedValue: String(format: "%.1f kg", oneRM)
        )
    }
}
