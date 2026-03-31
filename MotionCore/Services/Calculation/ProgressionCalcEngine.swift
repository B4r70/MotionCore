//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : ProgressionCalcEngine.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-08                                                       /
// Beschreibung  : Intelligentes Progressionssystem (Double Progression, Trend,     /
//                 Konfidenz, Auto-Detect Trainings-Level)                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Legacy-Empfehlung (für ProgressionBannerView im aktiven Workout)

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
struct ProgressionCalcEngine {

    // MARK: - Legacy API (für ActiveWorkoutView / ProgressionBannerView)

    /// Gibt eine Empfehlung zurück, wenn in allen letzten `sessionCount` Sessions
    /// der Ø-RIR einer Übung über dem `targetRIR` lag.
    func recommendation(
        for exerciseName: String,
        targetRIR: Int,
        progressionStep: Double,
        sessions: [StrengthSession],
        sessionCount: Int = 3
    ) -> ProgressionRecommendation? {

        guard sessionCount > 0 else { return nil }

        let relevantSessions = sessions
            .sorted { $0.date > $1.date }
            .filter { session in
                session.safeExerciseSets.contains {
                    matchesExercise($0, name: exerciseName)
                }
            }
            .prefix(sessionCount)

        guard relevantSessions.count == sessionCount else { return nil }

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

        let allAboveTarget = averageRIRsPerSession.allSatisfy { $0 > Double(targetRIR) }
        guard allAboveTarget, lastWeight > 0 else { return nil }

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

    // MARK: - Vollständige Analyse

    /// Analysiert eine Übung und gibt eine umfassende Progressions-Empfehlung zurück.
    func analyze(
        exercise: Exercise,
        sessions: [StrengthSession]
    ) -> ProgressionAnalysis {

        let snapshots = extractSnapshots(for: exercise.name, from: sessions)

        let daysSinceLast = snapshots.first.map { daysSince($0.date) } ?? 0
        let level = detectTrainingLevel(
            sessionCount: snapshots.count,
            daysSinceLastSession: daysSinceLast
        )
        let trend = analyzeTrend(snapshots: snapshots)
        let dpStatus = analyzeDoubleProgression(
            snapshots: snapshots,
            targetRange: exercise.repRangeMin...exercise.repRangeMax
        )
        let confidence = calculateConfidence(
            snapshots: snapshots,
            trend: trend,
            exercise: exercise
        )
        let action = determineAction(
            exercise: exercise,
            dpStatus: dpStatus,
            trend: trend,
            confidence: confidence,
            level: level
        )
        let suggestedKg: Double? = {
            if case .increaseWeight(let kg) = action { return kg }
            return nil
        }()

        return ProgressionAnalysis(
            exerciseName: exercise.name,
            exerciseUUID: exercise.apiID,
            analysisDate: Date(),
            currentWeight: snapshots.first?.weight ?? 0,
            currentRepsRange: (snapshots.first?.minReps ?? 0)...(snapshots.first?.maxReps ?? 0),
            targetRepsRange: exercise.repRangeMin...exercise.repRangeMax,
            trainingLevel: level,
            trend: trend,
            confidence: confidence,
            confidenceLevel: ProgressionConfidence(value: confidence),
            recommendedAction: action,
            suggestedWeight: suggestedKg.map { (snapshots.first?.weight ?? 0) + $0 },
            reasoningPoints: buildReasoning(
                snapshots: snapshots,
                dpStatus: dpStatus,
                trend: trend,
                exercise: exercise,
                level: level
            ),
            sessionsAnalyzed: snapshots.count,
            daysSinceLastSession: daysSinceLast,
            estimatedOneRepMax: snapshots.first?.estimatedOneRM,
            oneRepMaxTrend: analyzeOneRMTrend(snapshots: snapshots),
            repsProgress: dpStatus.progress,
            isReadyForWeightIncrease: dpStatus.readyForIncrease
        )
    }

    // MARK: - Session-Snapshots extrahieren

    func extractSnapshots(
        for exerciseName: String,
        from sessions: [StrengthSession]
    ) -> [SessionSnapshot] {

        sessions
            .sorted { $0.date > $1.date }
            .compactMap { session -> SessionSnapshot? in
                let workSets = session.safeExerciseSets.filter {
                    matchesExercise($0, name: exerciseName) &&
                    $0.setKind == .work &&
                    $0.isCompleted
                }
                guard !workSets.isEmpty else { return nil }

                let weight = workSets.compactMap { $0.weight > 0 ? $0.weight : nil }.max() ?? 0
                let reps = workSets.map { $0.reps }
                let rpeValues = workSets.map { $0.rpe }
                let totalVolume = workSets
                    .map { Double($0.reps) * $0.weight }
                    .reduce(0, +)

                let oneRM = workSets
                    .compactMap { set -> Double? in
                        guard set.reps > 0, set.weight > 0 else { return nil }
                        return set.weight * (1.0 + Double(set.reps) / 30.0)
                    }
                    .max()

                return SessionSnapshot(
                    date: session.date,
                    weight: weight,
                    reps: reps,
                    rpeValues: rpeValues,
                    totalVolume: totalVolume,
                    estimatedOneRM: oneRM
                )
            }
    }

    // MARK: - Trainings-Level erkennen

    private func detectTrainingLevel(
        sessionCount: Int,
        daysSinceLastSession: Int
    ) -> TrainingLevel {
        if daysSinceLastSession > 21 { return .returning }
        switch sessionCount {
        case ..<10:  return .beginner
        case 10..<50: return .intermediate
        default:     return .advanced
        }
    }

    // MARK: - Double Progression Analyse

    private struct DoubleProgressionStatus {
        let progress: Double                    // 0.0–1.0
        let readyForIncrease: Bool
        let consecutiveSessionsAtTop: Int
    }

    private func analyzeDoubleProgression(
        snapshots: [SessionSnapshot],
        targetRange: ClosedRange<Int>
    ) -> DoubleProgressionStatus {
        guard !snapshots.isEmpty else {
            return DoubleProgressionStatus(progress: 0, readyForIncrease: false, consecutiveSessionsAtTop: 0)
        }

        let topReps = targetRange.upperBound
        let rangeSize = Double(targetRange.upperBound - targetRange.lowerBound)

        let latestMinReps = snapshots.first?.minReps ?? targetRange.lowerBound
        let progress: Double = rangeSize > 0
            ? Double(latestMinReps - targetRange.lowerBound) / rangeSize
            : 0

        var consecutiveAtTop = 0
        for snapshot in snapshots {
            if snapshot.minReps >= topReps {
                consecutiveAtTop += 1
            } else {
                break
            }
        }

        return DoubleProgressionStatus(
            progress: min(1.0, max(0.0, progress)),
            readyForIncrease: consecutiveAtTop >= 2,
            consecutiveSessionsAtTop: consecutiveAtTop
        )
    }

    // MARK: - Trend-Analyse

    private func analyzeTrend(snapshots: [SessionSnapshot]) -> PerformanceTrend {
        guard snapshots.count >= 3 else { return .insufficient }

        let relevant = Array(snapshots.prefix(8))
        let values = relevant.compactMap { $0.estimatedOneRM ?? Optional($0.totalVolume) }
        guard values.count >= 3 else { return .insufficient }

        let slope = linearRegressionSlope(values.reversed())
        let variance = calculateVariance(values)
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return .insufficient }

        let cv = sqrt(variance) / mean
        if cv > 0.15 { return .volatile }

        let normalizedSlope = slope / mean
        switch normalizedSlope {
        case let s where s > 0.02:  return .improving
        case let s where s < -0.02: return .declining
        default:                    return .stable
        }
    }

    private func analyzeOneRMTrend(snapshots: [SessionSnapshot]) -> PerformanceTrend? {
        let values = snapshots.prefix(8).compactMap { $0.estimatedOneRM }
        guard values.count >= 3 else { return nil }
        let slope = linearRegressionSlope(values.reversed())
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return nil }
        let normalized = slope / mean
        if normalized > 0.02 { return .improving }
        if normalized < -0.02 { return .declining }
        return .stable
    }

    // MARK: - Konfidenz-Berechnung

    private func calculateConfidence(
        snapshots: [SessionSnapshot],
        trend: PerformanceTrend,
        exercise: Exercise
    ) -> Double {
        var confidence = 0.0

        // Faktor 1: Anzahl Sessions (max 0.3)
        confidence += min(0.3, Double(snapshots.count) * 0.05)

        // Faktor 2: Trend (max 0.25)
        switch trend {
        case .improving:             confidence += 0.25
        case .stable:                confidence += 0.15
        case .volatile:              confidence += 0.05
        case .declining, .insufficient: break
        }

        // Faktor 3: Konsistenz der letzten Sessions (max 0.25)
        if let cs = calculateConsistency(snapshots: snapshots) {
            confidence += cs * 0.25
        }

        // Faktor 4: RIR-Buffer über Ziel (max 0.2)
        if let avgRIR = snapshots.first?.averageRIR {
            let buffer = avgRIR - Double(exercise.targetRIR)
            if buffer > 0 { confidence += min(0.2, buffer * 0.1) }
        }

        return min(1.0, confidence)
    }

    private func calculateConsistency(snapshots: [SessionSnapshot]) -> Double? {
        guard snapshots.count >= 2 else { return nil }
        let recent = Array(snapshots.prefix(4))
        let volumes = recent.map { $0.totalVolume }
        guard volumes.first ?? 0 > 0 else { return nil }
        let variance = calculateVariance(volumes)
        let mean = volumes.reduce(0, +) / Double(volumes.count)
        let cv = mean > 0 ? sqrt(variance) / mean : 1.0
        return max(0.0, 1.0 - cv)
    }

    // MARK: - Empfehlung ableiten

    private func determineAction(
        exercise: Exercise,
        dpStatus: DoubleProgressionStatus,
        trend: PerformanceTrend,
        confidence: Double,
        level: TrainingLevel
    ) -> ProgressionAction {

        guard exercise.canRecommendProgression else { return .maintain }

        // Zu wenig Daten
        guard confidence >= 0.3 else { return .needMoreData }

        // Abwärtstrend — Deload prüfen
        if trend == .declining && confidence >= 0.5 { return .considerDeload }

        // Strategie anwenden
        let strategy = exercise.progressionStrategy

        switch strategy {
        case .manual:
            return .maintain

        case .double:
            if dpStatus.readyForIncrease {
                return .increaseWeight(kg: exercise.effectiveProgressionStep)
            } else if dpStatus.progress >= 0 {
                return .increaseReps
            }
            return .maintain

        case .standard, .micro, .aggressive:
            let step = exercise.effectiveProgressionStep
            if confidence >= 0.5 {
                return .increaseWeight(kg: step)
            } else if confidence >= 0.3 {
                return .maintain
            }
            return .needMoreData
        }
    }

    // MARK: - Begründungs-Texte

    private func buildReasoning(
        snapshots: [SessionSnapshot],
        dpStatus: DoubleProgressionStatus,
        trend: PerformanceTrend,
        exercise: Exercise,
        level: TrainingLevel
    ) -> [String] {
        var points: [String] = []

        points.append("\(snapshots.count) Session(s) analysiert")

        if let avgRIR = snapshots.first?.averageRIR {
            points.append(String(format: "Ø RIR: %.1f (Ziel: %d)", avgRIR, exercise.targetRIR))
        }

        if let oneRM = snapshots.first?.estimatedOneRM {
            points.append(String(format: "Geschätztes 1RM: %.1f kg", oneRM))
        }

        points.append("Trend: \(trend.displayName)")
        points.append("Trainings-Level: \(level.displayName)")

        if dpStatus.consecutiveSessionsAtTop > 0 {
            points.append("\(dpStatus.consecutiveSessionsAtTop)× oberes Rep-Limit erreicht")
        }

        return points
    }

    // MARK: - Hilfsmethoden

    private func matchesExercise(_ set: ExerciseSet, name: String) -> Bool {
        set.exerciseNameSnapshot == name || set.exerciseName == name
    }

    private func daysSince(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }

    private func linearRegressionSlope(_ values: [Double]) -> Double {
        let n = Double(values.count)
        guard n > 1 else { return 0 }
        let indices = values.indices.map { Double($0) }
        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map(*).reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return 0 }
        return (n * sumXY - sumX * sumY) / denominator
    }

    private func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        return values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
    }
}
