//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : ProgressionCalcEngine.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-08                                                       /
// Beschreibung  : RIR-basierte Auto-Progression für Kraft-Übungen                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Progressions-Empfehlung

struct ProgressionRecommendation {
    let exerciseName: String
    let currentWeight: Double
    let suggestedWeight: Double
    let progressionStep: Double
    let reason: String
    let sessionCount: Int
}

// MARK: - Progressions-Berechnungs-Engine

/// Pure struct — kein State, kein SwiftUI.
/// Vergleicht geloggten RIR (aus RPE) mit dem Ziel-RIR der letzten N Sessions.
struct ProgressionCalcEngine {

    /// Gibt eine Empfehlung zurück, wenn in allen letzten `sessionCount` Sessions
    /// der Ø-RIR einer Übung über dem `targetRIR` lag.
    func recommendation(
        for exerciseName: String,
        targetRIR: Int,
        progressionStep: Double,
        sessions: [StrengthSession],
        sessionCount: Int = 3
    ) -> ProgressionRecommendation? {

        // 1) Letzte N Sessions filtern, die diese Übung enthalten
        let relevantSessions = sessions
            .filter { session in
                session.safeExerciseSets.contains {
                    matchesExercise($0, name: exerciseName)
                }
            }
            .prefix(sessionCount)

        guard relevantSessions.count == sessionCount else { return nil }

        // 2) Durchschnittlichen RIR pro Session berechnen
        var averageRIRsPerSession: [Double] = []
        var lastWeight: Double = 0

        for session in relevantSessions {
            let workSets = session.safeExerciseSets.filter {
                matchesExercise($0, name: exerciseName) &&
                $0.setKind == .work &&
                $0.isCompleted &&
                $0.rpe > 0
            }

            guard !workSets.isEmpty else { return nil }

            let avgRIR = workSets.map { Double($0.calculatedRIR) }.reduce(0, +) / Double(workSets.count)
            averageRIRsPerSession.append(avgRIR)

            if lastWeight == 0 {
                lastWeight = workSets.compactMap { $0.weight > 0 ? $0.weight : nil }.max() ?? 0
            }
        }

        // 3) Alle Sessions müssen über dem Ziel-RIR liegen
        let allAboveTarget = averageRIRsPerSession.allSatisfy { $0 > Double(targetRIR) }
        guard allAboveTarget, lastWeight > 0 else { return nil }

        // 4) Empfehlung berechnen
        let avgTotal = averageRIRsPerSession.reduce(0, +) / Double(averageRIRsPerSession.count)
        let avgRIRFormatted = String(format: "%.1f", avgTotal)

        return ProgressionRecommendation(
            exerciseName: exerciseName,
            currentWeight: lastWeight,
            suggestedWeight: lastWeight + progressionStep,
            progressionStep: progressionStep,
            reason: "Ø RIR \(avgRIRFormatted) > Ziel \(targetRIR) in den letzten \(sessionCount) Sessions",
            sessionCount: sessionCount
        )
    }

    // MARK: - Hilfsmethoden

    private func matchesExercise(_ set: ExerciseSet, name: String) -> Bool {
        set.exerciseNameSnapshot == name || set.exerciseName == name
    }
}
