//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : PlanUpdateCalcEngine.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 21.03.2026                                                       /
// Beschreibung  : Analysiert abgeschlossene Sessions auf Planänderungen            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Plan-Update Calc Engine

struct PlanUpdateCalcEngine {

    // MARK: - Konfiguration

    let minWeightDelta: Double
    let minRepsDelta: Int
    let trendSessionCount: Int

    // MARK: - Öffentliche Analyse-Methode

    /// Analysiert den Plan und liefert einen Vorschlag für Änderungen.
    func analyze(plan: TrainingPlan) -> PlanUpdateProposal {
        // Nur abgeschlossene Sessions, neueste zuerst
        let allCompleted = (plan.derivedSessions ?? [])
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }

        // Filter: nur Sessions NACH dem letzten Update (wenn gesetzt)
        let filtered: [StrengthSession]
        if let lastUpdate = plan.lastUpdatedFromSession {
            filtered = allCompleted.filter { $0.date > lastUpdate }
        } else {
            filtered = allCompleted
        }

        // Limit auf trendSessionCount
        let sessions = Array(filtered.prefix(trendSessionCount))

        guard !sessions.isEmpty else {
            return PlanUpdateProposal(
                plan: plan,
                changes: [],
                analyzedSessionCount: 0,
                analyzedSessionDates: []
            )
        }

        let sessionDates = sessions.map { $0.date }
        var changes: [PlanUpdateChange] = []

        // Plan-Übungsgruppen (gruppiert nach groupKey)
        let planGroups = plan.groupedTemplateSets

        // Gewichts- und Satzanzahl-Trends pro Übungsgruppe prüfen
        for group in planGroups {
            guard let groupKey = group.first?.groupKey,
                  let exerciseName = group.first.map({ $0.exerciseNameSnapshot.isEmpty ? $0.exerciseName : $0.exerciseNameSnapshot }) else {
                continue
            }

            // Session-Sätze dieser Übungsgruppe sammeln (nur Work-Sets)
            let sessionSetsPerSession: [[ExerciseSet]] = sessions.map { session in
                session.safeExerciseSets
                    .filter { $0.groupKey == groupKey && $0.setKind == .work }
            }

            // Nur Sessions mit mindestens einem Set berücksichtigen
            let nonEmptySessions = sessionSetsPerSession.filter { !$0.isEmpty }

            if !nonEmptySessions.isEmpty {
                // Gewichts-Trend analysieren
                if let weightChange = analyzeWeightTrend(
                    planGroup: group,
                    sessionSetsPerSession: nonEmptySessions,
                    groupKey: groupKey,
                    exerciseName: exerciseName
                ) {
                    changes.append(weightChange)
                }

                // Satzanzahl-Trend analysieren
                if let setCountChange = analyzeSetCountTrend(
                    planGroup: group,
                    sessionSetsPerSession: nonEmptySessions,
                    groupKey: groupKey,
                    exerciseName: exerciseName
                ) {
                    changes.append(setCountChange)
                }
            }

            // Übung übersprungen? (in Sessions vorhanden, aber nie trainiert)
            let skippedCount = sessionSetsPerSession.filter { $0.isEmpty }.count
            if skippedCount > 0 {
                let outOf = sessions.count
                // Nur anzeigen wenn die Übung in mindestens der Hälfte übersprungen wurde
                if skippedCount * 2 >= outOf {
                    let skippedChange = PlanUpdateChange(
                        exerciseGroupKey: groupKey,
                        exerciseName: exerciseName,
                        changeType: .exerciseSkipped(timesSkipped: skippedCount, outOf: outOf),
                        isSelected: false // Übersprungene Übungen nie vorselektiert
                    )
                    changes.append(skippedChange)
                }
            }
        }

        // Neue Übungen erkennen (in Sessions, aber nicht im Plan)
        let newExerciseChanges = detectNewExercises(
            planGroups: planGroups,
            sessions: sessions
        )
        changes.append(contentsOf: newExerciseChanges)

        return PlanUpdateProposal(
            plan: plan,
            changes: changes,
            analyzedSessionCount: sessions.count,
            analyzedSessionDates: sessionDates,
            sourceSessionUUID: sessions.first?.sessionUUID.uuidString
        )
    }

    // MARK: - Private Analyse-Methoden

    /// Analysiert ob das Trainingsgewicht konsistent über dem Plan-Gewicht liegt.
    private func analyzeWeightTrend(
        planGroup: [ExerciseSet],
        sessionSetsPerSession: [[ExerciseSet]],
        groupKey: String,
        exerciseName: String
    ) -> PlanUpdateChange? {
        // Plan-Gewicht: Median der Work-Sets im Plan
        let planWorkSets = planGroup.filter { $0.setKind == .work }
        guard !planWorkSets.isEmpty else { return nil }
        let planWeight = medianWeight(of: planWorkSets)

        // Session-Mediangewichte berechnen
        let sessionMedians = sessionSetsPerSession.map { medianWeight(of: $0) }
        guard !sessionMedians.isEmpty else { return nil }

        // 2/3-Threshold: Mindestens 2/3 der Sessions müssen den Trend zeigen
        let threshold = max(1, Int(ceil(Double(sessionMedians.count) * 2.0 / 3.0)))
        let overallMedian = median(of: sessionMedians)

        let delta = overallMedian - planWeight
        guard abs(delta) >= minWeightDelta else { return nil }

        // Prüfen ob genug Sessions den Trend zeigen
        let trending: Int
        if delta > 0 {
            trending = sessionMedians.filter { $0 >= planWeight + minWeightDelta }.count
        } else {
            trending = sessionMedians.filter { $0 <= planWeight - minWeightDelta }.count
        }

        guard trending >= threshold else { return nil }

        // Erhöhung vorselektieren, Reduktion nicht
        let isSelected = delta > 0

        return PlanUpdateChange(
            exerciseGroupKey: groupKey,
            exerciseName: exerciseName,
            changeType: .weightUpdate(from: planWeight, to: overallMedian),
            isSelected: isSelected
        )
    }

    /// Analysiert ob die Satzanzahl konsistent vom Plan abweicht.
    private func analyzeSetCountTrend(
        planGroup: [ExerciseSet],
        sessionSetsPerSession: [[ExerciseSet]],
        groupKey: String,
        exerciseName: String
    ) -> PlanUpdateChange? {
        let planWorkSetCount = planGroup.filter { $0.setKind == .work }.count
        guard planWorkSetCount > 0 else { return nil }

        // Satzanzahl pro Session
        let sessionCounts = sessionSetsPerSession.map { $0.count }
        guard !sessionCounts.isEmpty else { return nil }

        // Häufigste Satzanzahl in den Sessions
        guard let mostCommonCount = mostFrequent(in: sessionCounts) else { return nil }
        guard mostCommonCount != planWorkSetCount else { return nil }
        guard abs(mostCommonCount - planWorkSetCount) >= 1 else { return nil }

        // 2/3-Threshold
        let threshold = max(1, Int(ceil(Double(sessionCounts.count) * 2.0 / 3.0)))
        let matchingCount = sessionCounts.filter { $0 == mostCommonCount }.count
        guard matchingCount >= threshold else { return nil }

        // Erhöhung vorselektieren, Reduktion nicht
        let isSelected = mostCommonCount > planWorkSetCount

        return PlanUpdateChange(
            exerciseGroupKey: groupKey,
            exerciseName: exerciseName,
            changeType: .setCountUpdate(from: planWorkSetCount, to: mostCommonCount),
            isSelected: isSelected
        )
    }

    /// Erkennt Übungen, die in Sessions trainiert wurden, aber nicht im Plan stehen.
    private func detectNewExercises(
        planGroups: [[ExerciseSet]],
        sessions: [StrengthSession]
    ) -> [PlanUpdateChange] {
        let planGroupKeys = Set(planGroups.compactMap { $0.first?.groupKey })

        // Alle in Sessions vorkommenden groupKeys
        var groupKeyOccurrences: [String: (count: Int, newestSets: [ExerciseSet])] = [:]

        for session in sessions {
            let sessionGroups = Dictionary(grouping: session.safeExerciseSets.filter { $0.setKind == .work }) { $0.groupKey }
            for (key, sets) in sessionGroups {
                if !planGroupKeys.contains(key) {
                    if let existing = groupKeyOccurrences[key] {
                        // Ältere Session: nur zählen (newestSets bleibt von neuerer Session)
                        groupKeyOccurrences[key] = (count: existing.count + 1, newestSets: existing.newestSets)
                    } else {
                        groupKeyOccurrences[key] = (count: 1, newestSets: sets)
                    }
                }
            }
        }

        var changes: [PlanUpdateChange] = []
        // 2/3-Schwelle: konsistent mit Gewichts- und Satzanzahl-Trend-Analyse
        let minOccurrences = max(1, Int(ceil(Double(sessions.count) * 2.0 / 3.0)))

        for (key, info) in groupKeyOccurrences where info.count >= minOccurrences {
            guard let firstSet = info.newestSets.first else { continue }
            let exerciseName = firstSet.exerciseNameSnapshot.isEmpty ? firstSet.exerciseName : firstSet.exerciseNameSnapshot

            // Snapshots aus neuester Session erstellen
            let snapshots = info.newestSets
                .sorted { $0.setNumber < $1.setNumber }
                .map { set in
                    ExerciseSetSnapshot(
                        exerciseName: set.exerciseName,
                        exerciseNameSnapshot: set.exerciseNameSnapshot,
                        exerciseUUIDSnapshot: set.exerciseUUIDSnapshot,
                        exerciseMediaAssetName: set.exerciseMediaAssetName,
                        isUnilateralSnapshot: set.isUnilateralSnapshot,
                        setNumber: set.setNumber,
                        weight: set.weight,
                        weightPerSide: set.weightPerSide,
                        reps: set.reps,
                        targetRepsMin: set.targetRepsMin,
                        targetRepsMax: set.targetRepsMax,
                        targetRIR: set.targetRIR,
                        setKind: set.setKind,
                        restSeconds: set.restSeconds,
                        sortOrder: set.sortOrder,
                        groupId: set.groupId,
                        supersetGroupId: set.supersetGroupId,
                        trackingMode: set.trackingMode,
                        duration: set.duration
                    )
                }

            // Metadaten für Hinweistext "In X von Y Sessions trainiert"
            let metadata = PlanUpdateChangeMetadata(
                sessionOccurrences: info.count,
                sessionsAnalyzed: sessions.count
            )

            let change = PlanUpdateChange(
                exerciseGroupKey: key,
                exerciseName: exerciseName,
                changeType: .exerciseAdded(sets: snapshots),
                isSelected: false, // Neue Übungen standardmäßig nicht vorselektiert
                metadata: metadata
            )
            changes.append(change)
        }

        return changes
    }

    // MARK: - Hilfs-Methoden

    private func medianWeight(of sets: [ExerciseSet]) -> Double {
        let weights = sets.map { $0.weight }.sorted()
        guard !weights.isEmpty else { return 0 }
        let mid = weights.count / 2
        if weights.count % 2 == 0 {
            return (weights[mid - 1] + weights[mid]) / 2.0
        } else {
            return weights[mid]
        }
    }

    private func median(of values: [Double]) -> Double {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        } else {
            return sorted[mid]
        }
    }

    private func mostFrequent(in values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        var counts: [Int: Int] = [:]
        for v in values { counts[v, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
