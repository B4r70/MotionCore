//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : MuscleRecoveryCalcEngine.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Berechnet Muskel-Erholungs-Scores aus den letzten 14 Tagen       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct MuscleRecoveryCalcEngine {

    // MARK: - Konstanten

    /// Basis-Erholungszeit pro Muskelgruppe in Stunden
    static let baseRecoveryHours: [MuscleGroup: Double] = [
        .chest: 60, .back: 72, .shoulders: 48, .arms: 48,
        .legs: 72, .glutes: 72, .core: 36, .other: 48, .fullBody: 72
    ]

    /// Gewichtungsfaktor für sekundäre Muskeln
    static let secondaryVolumeWeight: Double = 0.30

    /// Analysefenster in Tagen
    static let timeframeDays: Int = 14

    /// Halbwertszeit des exponentiellen Decays in Tagen
    static let decayHalfLifeDays: Double = 7.0

    // MARK: - Ausgabe-Reihenfolge

    /// Feste Anzeigereihenfolge der Muskelgruppen
    private static let outputOrder: [MuscleGroup] = [
        .chest, .back, .shoulders, .arms, .legs, .core, .glutes
    ]

    // MARK: - Haupt-Analyse

    /// Berechnet Erholungsstatus aller Muskelgruppen aus den letzten 14 Tagen
    static func analyze(sessions: [StrengthSession]) -> MuscleRecoveryAnalysis {
        let now = Date()
        let cutoff = now.addingTimeInterval(-Double(timeframeDays) * 86400)

        // 1. Nur abgeschlossene Sessions im Zeitfenster
        let relevantSessions = sessions.filter { $0.isCompleted && $0.date >= cutoff }

        // 2. Fatigue und letztes Trainingsdatum pro DetailedMuscle akkumulieren
        var fatigueByMuscle: [DetailedMuscle: Double] = [:]
        var lastTrainedByMuscle: [DetailedMuscle: Date] = [:]

        for session in relevantSessions {
            let sessionBodyWeight = session.bodyWeight > 0 ? session.bodyWeight : 70.0

            for set in session.safeExerciseSets
            where set.isCompleted && set.reps > 0 && set.setKind == .work {

                // Alter des Satzes in Tagen
                let ageInDays = now.timeIntervalSince(session.date) / 86400.0

                // Exponentieller Decay (Halbwertszeit 7 Tage)
                let decayFactor = pow(0.5, ageInDays / decayHalfLifeDays)

                // Volumen- und Intensitätsfaktor
                let volumeFactor = normalizedVolume(
                    weight: set.weight,
                    reps: set.reps,
                    sessionBodyWeight: sessionBodyWeight
                )
                let intensityFactor = intensityFromRIR(set)

                // Fatigue pro Satz
                let fatiguePerSet = volumeFactor * intensityFactor * decayFactor

                // Muskeln auflösen (Fallback-Kette identisch zu MuscleHeatmapCalcEngine)
                // TODO: extract to SharedMuscleResolver
                let primaryMuscles = resolveDetailedMuscles(for: set, type: .primary)
                let secondaryMuscles = resolveDetailedMuscles(for: set, type: .secondary)

                // Primäre Muskeln: volle Fatigue
                for muscle in primaryMuscles {
                    fatigueByMuscle[muscle, default: 0] += fatiguePerSet
                    updateLastTrained(&lastTrainedByMuscle, muscle: muscle, date: session.date)
                }

                // Sekundäre Muskeln: reduzierte Fatigue (30%)
                for muscle in secondaryMuscles {
                    fatigueByMuscle[muscle, default: 0] += fatiguePerSet * secondaryVolumeWeight
                    updateLastTrained(&lastTrainedByMuscle, muscle: muscle, date: session.date)
                }
            }
        }

        // 3. DetailedMuscleRecovery pro trainiertem Muskel berechnen
        var detailedScores: [DetailedMuscleRecovery] = []

        for muscle in DetailedMuscle.allCases {
            guard let lastTrained = lastTrainedByMuscle[muscle] else { continue }

            let totalFatigue = fatigueByMuscle[muscle] ?? 0
            let hoursSince = now.timeIntervalSince(lastTrained) / 3600.0
            let baseHours = baseRecoveryHours[muscle.parentGroup] ?? 48.0
            let adjusted = baseHours * fatigueMultiplier(totalFatigue)
            let recoveryPercent = min(100.0, (hoursSince / adjusted) * 100.0)

            detailedScores.append(DetailedMuscleRecovery(
                id: muscle.rawValue,
                muscle: muscle,
                recoveryPercent: recoveryPercent,
                lastTrainedDate: lastTrained,
                totalFatigueScore: totalFatigue
            ))
        }

        // 4. MuscleGroupRecovery aggregieren
        var muscleGroupScores: [MuscleGroupRecovery] = []

        for group in outputOrder {
            let groupDetails = detailedScores.filter { $0.muscleGroup == group }
            let wasTrainedInTimeframe = !groupDetails.isEmpty

            let recoveryPercent: Double
            let lastTrainedDate: Date?

            if wasTrainedInTimeframe {
                // Durchschnitt der trainierten DetailedMuscles
                let sum = groupDetails.reduce(0.0) { $0 + $1.recoveryPercent }
                recoveryPercent = sum / Double(groupDetails.count)
                lastTrainedDate = groupDetails.compactMap { $0.lastTrainedDate }.max()
            } else {
                // Nicht trainiert → vollständig erholt
                recoveryPercent = 100.0
                lastTrainedDate = nil
            }

            muscleGroupScores.append(MuscleGroupRecovery(
                id: group.rawValue,
                muscleGroup: group,
                recoveryPercent: recoveryPercent,
                muscleDetails: groupDetails,
                lastTrainedDate: lastTrainedDate,
                wasTrainedInTimeframe: wasTrainedInTimeframe
            ))
        }

        return MuscleRecoveryAnalysis(
            analysisDate: now,
            timeframeDays: timeframeDays,
            muscleGroupScores: muscleGroupScores,
            detailedScores: detailedScores
        )
    }

    // MARK: - Muscle Resolution (Fallback-Kette)
    // TODO: extract to SharedMuscleResolver (identisch zu MuscleHeatmapCalcEngine)

    private enum MuscleType { case primary, secondary }

    /// Ermittelt DetailedMuscles für ein ExerciseSet.
    /// Fallback-Kette:
    /// 1. exercise?.detailedPrimaryMuscles (feingranular, nach Enrichment)
    /// 2. exercise?.primaryMuscles → alle DetailedMuscle mit passendem parentGroup (grob)
    /// 3. ExerciseSet.primaryMuscleGroup (Name-basiert, letzter Fallback)
    private static func resolveDetailedMuscles(for set: ExerciseSet, type: MuscleType) -> [DetailedMuscle] {
        // 1. Feingranulare Daten vorhanden?
        if let exercise = set.exercise {
            let detailed = type == .primary ? exercise.detailedPrimaryMuscles : exercise.detailedSecondaryMuscles
            if !detailed.isEmpty { return detailed }
        }

        // 2. Grobe MuscleGroup → alle passenden DetailedMuscle
        let muscleGroups: [MuscleGroup]
        if let exercise = set.exercise {
            muscleGroups = type == .primary ? exercise.primaryMuscles : exercise.secondaryMuscles
        } else {
            // 3. Letzter Fallback: MuscleGroupMapper über ExerciseName
            if type == .primary {
                muscleGroups = [set.primaryMuscleGroup].compactMap { $0 }
            } else {
                muscleGroups = set.secondaryMuscleGroups
            }
        }

        // MuscleGroup → alle zugehörigen DetailedMuscle
        return muscleGroups.flatMap { group in
            DetailedMuscle.allCases.filter { $0.parentGroup == group }
        }
    }

    // MARK: - Hilfsfunktionen

    /// Letzte Trainingsdaten pro Muskel aktualisieren
    private static func updateLastTrained(
        _ dict: inout [DetailedMuscle: Date],
        muscle: DetailedMuscle,
        date: Date
    ) {
        if let existing = dict[muscle] {
            if date > existing { dict[muscle] = date }
        } else {
            dict[muscle] = date
        }
    }

    /// Intensitätsfaktor aus RIR-Daten des Satzes (0.5–1.5)
    private static func intensityFromRIR(_ set: ExerciseSet) -> Double {
        let rir: Int
        if set.rpeRecorded {
            // rpe = 10 - RIR (gespeicherte Semantik in MotionCore)
            rir = max(0, 10 - set.rpe)
        } else if set.targetRIR > 0 {
            rir = set.targetRIR
        } else {
            // Kein RIR-Datum vorhanden → neutraler Wert
            return 1.0
        }
        return max(0.5, min(1.5, 1.5 - Double(rir) * 0.25))
    }

    /// Normalisiertes Volumen eines Satzes (0.0–1.0)
    private static func normalizedVolume(
        weight: Double,
        reps: Int,
        sessionBodyWeight: Double
    ) -> Double {
        // Körpergewicht als Fallback für Bodyweight-Übungen
        let effectiveWeight = weight > 0 ? weight : (sessionBodyWeight > 0 ? sessionBodyWeight : 70.0)
        let raw = effectiveWeight * Double(reps)
        return min(1.0, raw / 500.0)
    }

    /// Erholungszeitverlängerung basierend auf akkumulierter Fatigue (0.8–1.5)
    private static func fatigueMultiplier(_ totalFatigue: Double) -> Double {
        let normalized = min(totalFatigue / 5.0, 1.0)
        return 0.8 + (normalized * 0.7)
    }
}
